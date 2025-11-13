# Instructions to Candidates

- You have **90 minutes** to complete 1 design question
- Use any LLM or AI coding assistant of your choice to help you build the application
- Your goal is to have the application running locally in your IDE and explain the code and reasoning behind it

# Boostly — boost morale, one kudos at a time

Build a working application that enables college students to recognize their peers, allocate monthly credits, and redeem earned rewards. The platform should encourage appreciation and engagement across student communities — a simple, transparent system for celebrating contributions and converting recognition into tangible value.

Use Python or Java as your programming language. You can choose any framework (e.g., Flask, FastAPI, Django for Python; Spring Boot for Java) and any database of your choice.

## Core Functionality

### 1. Recognition
Allows one student to recognize another and transfer a certain number of credits.

**Business Rules:**
- Each student receives **100 credits every month** (reset at the start of each calendar month)
- Students **cannot send credits to themselves** (self-recognition is not allowed)
- Each student has a **monthly sending limit of 100 credits** (per calendar month)
- A student cannot send more credits than they currently have in their balance
- A student cannot exceed their monthly sending limit

### 2. Endorsements
Enables students to endorse an existing recognition entry (like/cheer).

**Business Rules:**
- Each endorser can endorse a recognition entry **only once**
- Endorsements are just a count — they don't affect credit balances or any other functionality

### 3. Redemption
Lets students redeem the credits they've received.

**Business Rules:**
- Credits are converted into a fixed-value voucher at **₹5 per credit**
- When credits are redeemed, they are **permanently deducted** from the student's balance
- A student can only redeem credits they have received

## Step-Up Challenges

### 1. Credit Reset
Add a mechanism to automatically reset each student's monthly credit balance to 100 at the start of a new month, with an optional carry-forward of up to 50 unused credits.

**Business Rules:**
- Each student's available credits reset to 100 at the start of each calendar month
- Up to 50 unused credits from the previous month can be carried forward
- If a student has more than 50 unused credits, only 50 can be carried forward
- The monthly sending limit also resets to 100 credits

### 2. Leaderboard
Build a feature to list top recipients ranked by total credits received. Include both recognition counts and endorsement totals.

**Business Rules:**
- Rank students by total credits received (descending order)
- If two students have the same total credits, rank by student ID (ascending order)
- Include the total number of recognitions received by each student
- Include the total number of endorsements received across all recognitions
- Support a limit parameter to control how many top students are returned

## Deliverables

### Folder Structure
Organize your submission using the following folder structure in your GitHub repository:

```
your-repository/
├── src/                           # All source code goes here
│   └── readme.md                  # Project documentation (setup, API endpoints, etc.)
├── prompt/                        # LLM chat exports go here
│   └── llm-chat-export.txt        # Exported LLM/AI assistant conversations
└── test-cases/                    # Test cases documentation goes here
    └── test-cases.txt             # Documentation on how to run each use case
```

### Required Files

1. **Complete source code** in the `src/` folder

2. **readme.md** in the `src/` folder with:
   - Setup instructions
   - Run instructions
   - API endpoints documentation
   - Sample requests and responses


3. **LLM Chat Export** - Update `prompt/llm-chat-export.txt`:
   - If you used LLMs/AI assistants, paste your complete exported conversation in this file
   - Replace the placeholder content with your actual LLM chat export

4. **Test Cases Documentation** - Update `test-cases/test-cases.txt`:
   - Document how to run each use case from the problem (Recognition, Endorsements, Redemption)
   - For each core functionality, include:
     - How to test the feature
     - Steps to execute the test
     - Expected results
   - Replace the placeholder content with your test case documentation

---

# How to Submit Your Assignment

Once you have finished developing the app locally and it is working. Follow these steps to submit your completed assignment:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/raso-jr/ai-coding-round.git
   cd ai-coding-round
   ```

2. **Add your code** to the cloned repository:
   - Place all your source code in the `src/` folder
   - Update `src/readme.md` with your project documentation
   - Update `prompt/llm-chat-export.txt` with your LLM chat export (if applicable)
   - Update `test-cases/test-cases.txt` with your test case documentation

3. **Create a public GitHub repository** with the following naming format:
   ```
   firstname-lastname-collegeid
   ```
   Example: `phunsuk-wangdu-2022CS001`
   
   - Go to GitHub and create a new repository
   - **Make it public**
   - Do not initialize with a README (you already have one from the cloned repo)

4. **Verify all required files** are included:
   - Complete source code in `src/`
   - `src/readme.md` updated with setup, run instructions, and API documentation
   - Sample requests (cURL/Postman) with example responses (can be in `src/readme.md`)
   - `prompt/llm-chat-export.txt` updated with your LLM chat export (if you used LLMs)
   - `test-cases/test-cases.txt` updated with documentation on how to run each use case

5. **Verify your application** runs locally and is ready to demo

6. **Push your code to your GitHub repository**:
   ```bash
   git remote remove origin
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   git add .
   git commit -m "Initial submission"
   git push -u origin main
   ```
   Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your GitHub username and repository name.

7. **Share your repository link**:
   - Fill in the [Google form](https://forms.gle/rjogrkweA6WTqvbq7) with relevant info
   - Submit your repository URL in the form: `https://github.com/YOUR_USERNAME/YOUR_REPO_NAME`

---

***Remember: You are using LLMs and they hallucinate. Your ability to explain the code, think logically, and design effectively will be the key focus.***

***Good Luck!***
