#!/usr/bin/env node

/**
 * Node.js Intl.NumberFormat compatibility comparator
 *
 * This script accepts test cases as JSON input and outputs Node.js
 * Intl.NumberFormat results for comparison with Foxtail formatting.
 *
 * Usage:
 *   node comparator.js < test_cases.json
 *
 * Input format:
 * {
 *   "test_cases": [
 *     {
 *       "id": "test_001",
 *       "value": 1234.56,
 *       "locale": "en-US",
 *       "options": {
 *         "style": "decimal",
 *         "minimumFractionDigits": 2
 *       }
 *     }
 *   ]
 * }
 *
 * Output format:
 * {
 *   "results": [
 *     {
 *       "id": "test_001",
 *       "result": "1,234.56",
 *       "error": null
 *     }
 *   ]
 * }
 */

const fs = require('fs');

function formatNumber(value, locale, options = {}) {
  try {
    const formatter = new Intl.NumberFormat(locale, options);
    return {
      result: formatter.format(value),
      error: null
    };
  } catch (error) {
    return {
      result: null,
      error: error.message
    };
  }
}

function processTestCases(testCases) {
  const results = testCases.map(testCase => {
    const { id, value, locale, options } = testCase;
    const { result, error } = formatNumber(value, locale, options);

    return {
      id,
      result,
      error
    };
  });

  return { results };
}

// Read JSON input from stdin
let inputData = '';

process.stdin.setEncoding('utf8');

process.stdin.on('readable', () => {
  let chunk;
  while ((chunk = process.stdin.read()) !== null) {
    inputData += chunk;
  }
});

process.stdin.on('end', () => {
  try {
    const input = JSON.parse(inputData);
    const output = processTestCases(input.test_cases || []);
    console.log(JSON.stringify(output, null, 2));
  } catch (error) {
    console.error('Error processing input:', error.message);
    process.exit(1);
  }
});