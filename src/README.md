# Boostly: Peer-Recognition API

Boostly is a Flask-based REST API for a peer-to-peer recognition and rewards system. It allows students to give and receive credits, endorse recognitions, and redeem credits for vouchers.

## Setup Instructions

### 1. Create a Conda Environment
First, create and activate a Conda environment to keep project dependencies isolated.

```bash
# Create a new Conda environment (e.g., named 'boostly-env')
conda create --name boostly-env python=3.10

# Activate the environment
conda activate boostly-env
```

### 2. Install Requirements
Install the necessary Python packages using the `requirements.txt` file.

```bash
pip install -r src/requirements.txt
```

### 3. Initialize the Database
Create the SQLite database and tables using the custom Flask CLI command.

```bash
# Run the database creation command
flask --app src/app db-create-all
```
This will create a `boostly.db` file in the `src` directory.

## Run Instructions
To start the development server, run the following command:

```bash
flask --app src/app run
```
The API will be available at `http://127.0.0.1:5000`.

---

## API Endpoints

### Student Management

#### Create a New Student
* **Method:** `POST`
* **URL:** `/students`
* **Description:** Registers a new student in the system.
* **cURL Request:**
  ```bash
  curl -X POST http://127.0.0.1:5000/students \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser1", "email": "test1@example.com"}'
  ```
``` bash
curl -X POST http://127.0.0.1:5000/students \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser2", "email": "test2@example.com"}'
  ```


* **Success Response (201):**
  ```json
  {
    "id": 1,
    "username": "testuser1",
    "email": "test1@example.com",
    "redeemable_credits": 0,
    "sending_credits": 100
  }
  ```

#### Get Student Details
* **Method:** `GET`
* **URL:** `/students/<id>`
* **Description:** Retrieves details for a specific student.
* **cURL Request:**
  ```bash
  curl http://127.0.0.1:5000/students/1
  ```
* **Success Response (200):**
  ```json
  {
    "id": 1,
    "username": "testuser1",
    "email": "test1@example.com",
    "redeemable_credits": 20,
    "sending_credits": 80
  }
  ```

### Core Features

#### Create a Recognition
* **Method:** `POST`
* **URL:** `/recognitions`
* **Description:** Allows one student to recognize another and transfer credits.
* **cURL Request:**
  ```bash
  curl -X POST http://127.0.0.1:5000/recognitions \
  -H "Content-Type: application/json" \
  -d '{"sender_id": 1, "receiver_id": 2, "credits": 20, "message": "Great presentation!"}'
  ```
* **Success Response (201):**
  ```json
  {
    "id": 1,
    "sender_id": 1,
    "receiver_id": 2,
    "credits": 20,
    "message": "Great presentation!",
    "timestamp": "2023-10-27T10:00:00.123456"
  }
  ```
* **Error Response (400 - Insufficient Credits):**
  ```json
  {
    "error": "Insufficient sending credits"
  }
  ```

#### Endorse a Recognition
* **Method:** `POST`
* **URL:** `/endorsements`
* **Description:** Allows a student to endorse a recognition given to someone else.
* **cURL Request:**
  ```bash
  curl -X POST http://127.0.0.1:5000/endorsements \
  -H "Content-Type: application/json" \
  -d '{"endorser_id": 3, "recognition_id": 1}'
  ```
* **Success Response (201):**
  ```json
  {
    "message": "Endorsement successful"
  }
  ```
* **Error Response (409 - Duplicate Endorsement):**
  ```json
  {
    "error": "You have already endorsed this recognition"
  }
  ```

#### Redeem Credits
* **Method:** `POST`
* **URL:** `/redeem`
* **Description:** Redeems a student's `redeemable_credits` for a voucher.
* **cURL Request:**
  ```bash
  curl -X POST http://127.0.0.1:5000/redeem \
  -H "Content-Type: application/json" \
  -d '{"student_id": 2, "credits_to_redeem": 15}'
  ```
* **Success Response (200):**
  ```json
  {
    "message": "Redemption successful!",
    "voucher_value_inr": 75,
    "new_redeemable_balance": 5
  }
  ```
* **Error Response (400 - Insufficient Credits):**
  ```json
  {
    "error": "Insufficient redeemable credits"
  }
  ```

#### Get Leaderboard
* **Method:** `GET`
* **URL:** `/leaderboard`
* **Description:** Retrieves a ranked list of students based on credits received.
* **cURL Request:**
  ```bash
  curl "http://127.0.0.1:5000/leaderboard?limit=5"
  ```
* **Success Response (200):**
  ```json
  [
    {
      "student_id": 2,
      "username": "testuser2",
      "total_credits_received": 50,
      "total_recognitions_received": 2,
      "total_endorsements_received": 3
    },
    {
      "student_id": 4,
      "username": "testuser4",
      "total_credits_received": 30,
      "total_recognitions_received": 1,
      "total_endorsements_received": 1
    }
  ]
  ```
