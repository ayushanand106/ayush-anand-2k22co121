import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import func, desc
from sqlalchemy.exc import IntegrityError
from datetime import datetime
from flask_apscheduler import APScheduler

from models import db, Student, Recognition, Endorsement

# Initialize Flask App
app = Flask(__name__)
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'boostly.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize SQLAlchemy
db.init_app(app)

# Initialize APScheduler
scheduler = APScheduler()
scheduler.init_app(app)
scheduler.start()

# --- Database Initialization ---
@app.cli.command("db-create-all")
def db_create_all():
    """Creates the database tables."""
    db.create_all()
    print("Database tables created.")

# --- Step 3: Credit Reset Scheduler ---
def reset_monthly_credits():
    """
    Reset sending_credits for all students at the beginning of the month.
    Carries over a maximum of 50 credits from the previous month.
    """
    with app.app_context():
        try:
            students = Student.query.all()
            for student in students:
                carry_over = min(student.sending_credits, 50)
                student.sending_credits = 100 + carry_over
            db.session.commit()
            print(f"[{datetime.utcnow()}] Monthly credit reset complete for {len(students)} students.")
        except Exception as e:
            db.session.rollback()
            print(f"Error during monthly credit reset: {e}")

# Schedule the job to run on the 1st day of every month at midnight
@scheduler.task('cron', id='reset_credits_job', day='1', hour='0', minute='0')
def scheduled_reset():
    reset_monthly_credits()


# --- API Endpoints ---

# --- Step 2a: Student Management ---
@app.route('/students', methods=['POST'])
def create_student():
    """Create a new student."""
    data = request.get_json()
    if not data or not 'username' in data or not 'email' in data:
        return jsonify({"error": "Username and email are required"}), 400

    new_student = Student(username=data['username'], email=data['email'])
    try:
        db.session.add(new_student)
        db.session.commit()
        return jsonify(new_student.to_dict()), 201
    except IntegrityError:
        db.session.rollback()
        return jsonify({"error": "Username or email already exists"}), 409
    
    
    
    
@app.route('/students', methods=['GET'])
def get_students():
    """
    Get a list of students, with optional filtering
    by username or email.
    """
    # Get query parameters
    username = request.args.get('username')
    email = request.args.get('email')

    # Start with a base query for all students
    query = Student.query

    if username:
        # Use .ilike() for a case-insensitive partial search
        query = query.filter(Student.username.ilike(f'%{username}%'))
    
    if email:
        # Use func.lower() for a case-insensitive exact match
        query = query.filter(func.lower(Student.email) == email.lower())

    students = query.all()
    
    # Return a list of student dictionaries
    return jsonify([student.to_dict() for student in students])





@app.route('/students/<int:id>', methods=['GET'])
def get_student(id):
    """Get a student's details."""
    student = Student.query.get_or_404(id)
    return jsonify(student.to_dict())

# --- Step 2b: Recognition ---
@app.route('/recognitions', methods=['POST'])
def create_recognition():
    """Create a new recognition and transfer credits."""
    data = request.get_json()
    sender_id = data.get('sender_id')
    receiver_id = data.get('receiver_id')
    credits = data.get('credits')
    message = data.get('message')

    if not all([sender_id, receiver_id, credits]):
        return jsonify({"error": "sender_id, receiver_id, and credits are required"}), 400

    if not isinstance(credits, int) or credits <= 0:
        return jsonify({"error": "Credits must be a positive integer"}), 400

    if sender_id == receiver_id:
        return jsonify({"error": "Sender and receiver cannot be the same person"}), 400

    sender = Student.query.get(sender_id)
    receiver = Student.query.get(receiver_id)

    if not sender or not receiver:
        return jsonify({"error": "Sender or receiver not found"}), 404

    if sender.sending_credits < credits:
        return jsonify({"error": "Insufficient sending credits"}), 400

    try:
        sender.sending_credits -= credits
        receiver.redeemable_credits += credits

        new_recognition = Recognition(
            sender_id=sender_id,
            receiver_id=receiver_id,
            credits=credits,
            message=message
        )
        db.session.add(new_recognition)
        db.session.commit()
        return jsonify(new_recognition.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": "An internal error occurred", "details": str(e)}), 500

# --- Step 2c: Endorsements ---
@app.route('/endorsements', methods=['POST'])
def create_endorsement():
    """Endorse an existing recognition."""
    data = request.get_json()
    endorser_id = data.get('endorser_id')
    recognition_id = data.get('recognition_id')

    if not all([endorser_id, recognition_id]):
        return jsonify({"error": "endorser_id and recognition_id are required"}), 400

    endorser = Student.query.get(endorser_id)
    recognition = Recognition.query.get(recognition_id)

    if not endorser or not recognition:
        return jsonify({"error": "Endorser or recognition not found"}), 404

    new_endorsement = Endorsement(
        endorser_id=endorser_id,
        recognition_id=recognition_id
    )
    try:
        db.session.add(new_endorsement)
        db.session.commit()
        return jsonify({"message": "Endorsement successful"}), 201
    except IntegrityError:
        db.session.rollback()
        return jsonify({"error": "You have already endorsed this recognition"}), 409

# --- Step 2d: Redemption ---
@app.route('/redeem', methods=['POST'])
def redeem_credits():
    """Redeem received credits for a voucher."""
    data = request.get_json()
    student_id = data.get('student_id')
    credits_to_redeem = data.get('credits_to_redeem')

    if not all([student_id, credits_to_redeem]):
        return jsonify({"error": "student_id and credits_to_redeem are required"}), 400
    
    if not isinstance(credits_to_redeem, int) or credits_to_redeem <= 0:
        return jsonify({"error": "Credits to redeem must be a positive integer"}), 400

    student = Student.query.get(student_id)
    if not student:
        return jsonify({"error": "Student not found"}), 404

    if student.redeemable_credits < credits_to_redeem:
        return jsonify({"error": "Insufficient redeemable credits"}), 400

    voucher_value_inr = credits_to_redeem * 5

    try:
        student.redeemable_credits -= credits_to_redeem
        db.session.commit()
        return jsonify({
            "message": "Redemption successful!",
            "voucher_value_inr": voucher_value_inr,
            "new_redeemable_balance": student.redeemable_credits
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": "An internal error occurred", "details": str(e)}), 500

# --- Step 4: Leaderboard Endpoint ---
@app.route('/leaderboard', methods=['GET'])
def get_leaderboard():
    """Get a ranked leaderboard of students."""
    limit = request.args.get('limit', 10, type=int)

    # Subquery to get endorsement counts per recognition
    endorsement_subquery = db.session.query(
        Recognition.id.label('recognition_id'),
        func.count(Endorsement.id).label('endorsement_count')
    ).join(Endorsement, Endorsement.recognition_id == Recognition.id, isouter=True)\
     .group_by(Recognition.id).subquery()

    # Main query
    leaderboard_data = db.session.query(
        Student.id.label('student_id'),
        Student.username,
        func.sum(Recognition.credits).label('total_credits_received'),
        func.count(Recognition.id).label('total_recognitions_received'),
        func.sum(endorsement_subquery.c.endorsement_count).label('total_endorsements_received')
    ).join(Recognition, Student.id == Recognition.receiver_id)\
     .join(endorsement_subquery, Recognition.id == endorsement_subquery.c.recognition_id, isouter=True)\
     .group_by(Student.id, Student.username)\
     .order_by(desc('total_credits_received'), Student.id.asc())\
     .limit(limit).all()

    result = [
        {
            "student_id": row.student_id,
            "username": row.username,
            "total_credits_received": int(row.total_credits_received or 0),
            "total_recognitions_received": int(row.total_recognitions_received or 0),
            "total_endorsements_received": int(row.total_endorsements_received or 0)
        } for row in leaderboard_data
    ]

    return jsonify(result)

if __name__ == '__main__':
    app.run(debug=True)
