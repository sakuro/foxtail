#!/usr/bin/env node

/**
 * Node.js Intl.NumberFormat and Intl.DateTimeFormat compatibility comparator
 *
 * This script accepts test cases as JSON input and outputs Node.js
 * Intl formatting results for comparison with Foxtail formatting.
 *
 * Usage:
 *   node comparator.js < test_cases.json
 *
 * Input format:
 * {
 *   "number_test_cases": [
 *     {
 *       "id": "number_test_001",
 *       "value": 1234.56,
 *       "locale": "en-US",
 *       "options": {
 *         "style": "decimal",
 *         "minimumFractionDigits": 2
 *       }
 *     }
 *   ],
 *   "datetime_test_cases": [
 *     {
 *       "id": "datetime_test_001",
 *       "value": "2023-01-15T10:30:00Z",
 *       "locale": "en-US",
 *       "options": {
 *         "dateStyle": "medium",
 *         "timeStyle": "short"
 *       }
 *     }
 *   ]
 * }
 *
 * Output format:
 * {
 *   "number_results": [...],
 *   "datetime_results": [...]
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

function formatDateTime(value, locale, options = {}) {
  try {
    // Parse the input value into a Date object
    let date;
    if (typeof value === 'string') {
      date = new Date(value);
    } else if (typeof value === 'number') {
      // Assume Unix timestamp (milliseconds or seconds)
      const timestamp = value > 1000000000000 ? value : value * 1000;
      date = new Date(timestamp);
    } else {
      date = new Date(value);
    }

    if (isNaN(date.getTime())) {
      throw new Error(`Invalid date: ${value}`);
    }

    const formatter = new Intl.DateTimeFormat(locale, options);
    return {
      result: formatter.format(date),
      error: null
    };
  } catch (error) {
    return {
      result: null,
      error: error.message
    };
  }
}

function processNumberTestCases(testCases) {
  const results = testCases.map(testCase => {
    const { id, value, locale, options } = testCase;
    const { result, error } = formatNumber(value, locale, options);

    return {
      id,
      result,
      error
    };
  });

  return results;
}

function processDateTimeTestCases(testCases) {
  const results = testCases.map(testCase => {
    const { id, value, locale, options } = testCase;
    const { result, error } = formatDateTime(value, locale, options);

    return {
      id,
      result,
      error
    };
  });

  return results;
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

    // Handle both old format (test_cases) and new format (number_test_cases/datetime_test_cases)
    let output = {};

    if (input.test_cases) {
      // Old format - assume these are number test cases
      output.results = processNumberTestCases(input.test_cases);
    } else {
      // New format with separate test case types
      if (input.number_test_cases) {
        output.number_results = processNumberTestCases(input.number_test_cases);
      }

      if (input.datetime_test_cases) {
        output.datetime_results = processDateTimeTestCases(input.datetime_test_cases);
      }
    }

    console.log(JSON.stringify(output, null, 2));
  } catch (error) {
    console.error('Error processing input:', error.message);
    process.exit(1);
  }
});