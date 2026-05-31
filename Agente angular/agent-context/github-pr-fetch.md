# 📡 GitHub Pull Request Fetching Guide

This document explains how AI agents should retrieve branch changes from GitHub when analyzing a Pull Request.

## 🛠️ Prerequisites
You must use the `bash` tool with the GitHub CLI (`gh`) to interact with Pull Requests. Do not attempt to parse the web page HTML.

## 📥 Step 1: Get the PR Files
To see what files were added, modified, or deleted in the PR, use the following command:
```bash
gh pr view <pr-number-or-url> --json files
```
This will return a JSON array of the files changed. You must use this list to categorize the changes (e.g., Is it a newly created component file? Is it an existing component? Is it just a bug fix?).

## 🔍 Step 2: Get the Code Differences (Diff)
Once you know which files to look at, you can fetch the exact code changes (diff):
```bash
gh pr diff <pr-number-or-url>
```
*Note: If the diff is too large, you might want to fetch the diff for a specific file by reading the actual file on the local file system after checking out the branch, or using `git diff origin/main...HEAD -- <filepath>`.*

## 🧠 Step 3: Analyze the Context
Based on the `files` array and the `diff`, determine the nature of the change for each file:
1. **New Component:** If a `.ts`, `.html`, or `.scss` file was created under a new component directory.
2. **Old Component / Bug Fix:** If an existing file was modified. (Rules for this will be defined separately).

Once you have the diff and the categorization, apply the specific rules found in the `.github/skills/gitkraken-pr-analysis/references/` folder.
