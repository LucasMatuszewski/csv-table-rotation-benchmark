#!/usr/bin/env node

/**
 * CLI entry point for the table rotation tool.
 */

import { main } from './cli.js';

// Run the CLI
main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
