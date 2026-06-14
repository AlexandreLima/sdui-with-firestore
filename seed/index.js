import fs from 'fs/promises';
import path from 'path';
import process from 'process';
import net from 'net';
import { fileURLToPath } from 'url';
import admin from 'firebase-admin';

// ANSI escape codes for pretty terminal logging
const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
};

function logInfo(message) {
  console.log(`${colors.cyan}[INFO]${colors.reset} ${message}`);
}

function logSuccess(message) {
  console.log(`${colors.green}[SUCCESS]${colors.reset} ${colors.bold}${message}${colors.reset}`);
}

function logWarning(message) {
  console.log(`${colors.yellow}[WARNING]${colors.reset} ${message}`);
}

function logError(message, error = null) {
  console.error(`${colors.red}[ERROR]${colors.reset} ${colors.bold}${message}${colors.reset}`);
  if (error) {
    console.error(error);
  }
}

// Helper to check if a local port is reachable
function checkPort(host, port, timeout = 1000) {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    let status = false;

    socket.setTimeout(timeout);

    socket.on('connect', () => {
      status = true;
      socket.destroy();
    });

    socket.on('timeout', () => {
      socket.destroy();
    });

    socket.on('error', () => {
      socket.destroy();
    });

    socket.on('close', () => {
      resolve(status);
    });

    socket.connect(port, host);
  });
}

// Helper to wrap a promise with a timeout
function withTimeout(promise, timeoutMs, errorMessage) {
  return Promise.race([
    promise,
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error(errorMessage)), timeoutMs)
    )
  ]);
}

// Get current directory in ES Modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Constants
const COLLECTION_NAME = 'sdui_templates';
const RELATIVE_ASSETS_PATH = '../sdui_with_firestore/assets/sdui';
const DEFAULT_EMULATOR_HOST = '127.0.0.1:8080';
const DEFAULT_EMULATOR_PROJECT = 'demo-sdui-firestore';

async function main() {
  console.log(`\n${colors.bold}${colors.cyan}=========================================`);
  console.log(`🚀 Firestore SDUI Template Seed Utility`);
  console.log(`=========================================${colors.reset}\n`);

  // Parse arguments
  const args = process.argv.slice(2);
  const useEmulatorOpt = args.includes('--emulator') || args.includes('-e');
  const customServiceAccountPath = args.find(arg => arg.startsWith('--key='))?.split('=')[1];

  let isEmulator = false;

  // 1. Determine connection strategy
  if (useEmulatorOpt || process.env.FIRESTORE_EMULATOR_HOST) {
    isEmulator = true;
    if (!process.env.FIRESTORE_EMULATOR_HOST) {
      process.env.FIRESTORE_EMULATOR_HOST = DEFAULT_EMULATOR_HOST;
    }
    logInfo(`Using Firestore Emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`);
    
    // Check if emulator port is actually open
    const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
    const parts = emulatorHost.split(':');
    const host = parts[0] || '127.0.0.1';
    const port = parseInt(parts[1] || '8080', 10);

    const isReachable = await checkPort(host, port, 1500);
    if (!isReachable) {
      logError(`Firestore Emulator is not reachable at ${host}:${port}.`);
      console.log(`\n${colors.bold}Please make sure your local Firebase Emulator is running.${colors.reset}`);
      console.log(`You can start it by running:`);
      console.log(`  ${colors.green}firebase emulators:start${colors.reset}\n`);
      process.exit(1);
    }

    // Initialize admin app for emulator
    admin.initializeApp({
      projectId: process.env.GCLOUD_PROJECT || DEFAULT_EMULATOR_PROJECT,
    });
  } else {
    // Check credentials for production/staging connection
    const serviceAccountPath = customServiceAccountPath || path.join(__dirname, 'service-account.json');
    let hasServiceAccount = false;

    try {
      await fs.access(serviceAccountPath);
      hasServiceAccount = true;
    } catch (e) {
      // Not accessible (quietly log or ignore if fallback is available)
    }

    if (hasServiceAccount) {
      logInfo(`Initializing Firebase Admin using credentials file: ${serviceAccountPath}`);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccountPath),
      });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      logInfo(`Initializing Firebase Admin using GOOGLE_APPLICATION_CREDENTIALS env var`);
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
    } else {
      logError('No database configuration found.');
      console.log(`\nTo run this seed script, please do one of the following:`);
      console.log(`  1. ${colors.bold}Use local emulator:${colors.reset} Run with ${colors.cyan}--emulator${colors.reset} flag.`);
      console.log(`     Example: ${colors.green}npm run seed -- --emulator${colors.reset}`);
      console.log(`  2. ${colors.bold}Use production key:${colors.reset} Place your service account JSON file at:`);
      console.log(`     ${colors.white}${path.join(__dirname, 'service-account.json')}${colors.reset}`);
      console.log(`  3. ${colors.bold}Set environment variable:${colors.reset} Define ${colors.cyan}GOOGLE_APPLICATION_CREDENTIALS${colors.reset}.`);
      console.log(`  4. ${colors.bold}Specify key path:${colors.reset} Pass the path via ${colors.cyan}--key=/path/to/key.json${colors.reset}.\n`);
      process.exit(1);
    }
  }

  const db = admin.firestore();
  
  // 2. Scan and load templates
  const assetsDir = path.resolve(__dirname, RELATIVE_ASSETS_PATH);
  logInfo(`Scanning SDUI template directory: ${assetsDir}`);

  let files = [];
  try {
    const allFiles = await fs.readdir(assetsDir);
    files = allFiles.filter(file => file.endsWith('.json'));
  } catch (err) {
    logError(`Could not access SDUI directory: ${assetsDir}`, err);
    process.exit(1);
  }

  if (files.length === 0) {
    logWarning(`No JSON templates found in directory: ${assetsDir}`);
    process.exit(0);
  }

  logInfo(`Found ${files.length} JSON template(s) to process.`);
  console.log('');

  let uploadCount = 0;
  let failCount = 0;

  for (const file of files) {
    const filePath = path.join(assetsDir, file);
    const docId = path.basename(file, '.json');
    logInfo(`Processing: ${file} (docId: "${docId}")`);

    try {
      const fileContent = await fs.readFile(filePath, 'utf-8');
      
      // Parse to ensure valid JSON syntax
      let parsedTemplate;
      try {
        parsedTemplate = JSON.parse(fileContent);
      } catch (jsonErr) {
        throw new Error(`Invalid JSON syntax in file: ${jsonErr.message}`);
      }

      // Write to Firestore with a timeout to prevent infinite hang on network issues
      logInfo(`Uploading template to Firestore collection "${COLLECTION_NAME}/${docId}"...`);
      await withTimeout(
        db.collection(COLLECTION_NAME).doc(docId).set({
          template: parsedTemplate,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }),
        5000,
        'Connection to Firestore timed out. Please check if your database host is reachable.'
      );

      logSuccess(`Uploaded successfully: ${docId}`);
      uploadCount++;
    } catch (err) {
      logError(`Failed to process/upload template from ${file}`, err);
      failCount++;
    }
    console.log('');
  }

  console.log(`=========================================`);
  console.log(`🏁 Seed execution finished.`);
  console.log(`📈 Summary:`);
  console.log(`   - Total processed: ${files.length}`);
  console.log(`   - ${colors.green}Successful uploads: ${uploadCount}${colors.reset}`);
  if (failCount > 0) {
    console.log(`   - ${colors.red}Failed uploads: ${failCount}${colors.reset}`);
  }
  console.log(`=========================================\n`);

  if (failCount > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

main().catch(err => {
  logError('Unhandled script error occurred', err);
  process.exit(1);
});
