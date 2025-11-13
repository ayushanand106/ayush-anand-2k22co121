from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class Student(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    redeemable_credits = db.Column(db.Integer, nullable=False, default=0)
    sending_credits = db.Column(db.Integer, nullable=False, default=100)

    recognitions_sent = db.relationship('Recognition', foreign_keys='Recognition.sender_id', back_populates='sender', lazy=True)
    recognitions_received = db.relationship('Recognition', foreign_keys='Recognition.receiver_id', back_populates='receiver', lazy=True)
    endorsements_given = db.relationship('Endorsement', back_populates='endorser', lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "redeemable_credits": self.redeemable_credits,
            "sending_credits": self.sending_credits
        }

class Recognition(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    message = db.Column(db.String(280), nullable=True)
    credits = db.Column(db.Integer, nullable=False)
    timestamp = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    sender_id = db.Column(db.Integer, db.ForeignKey('student.id'), nullable=False)
    receiver_id = db.Column(db.Integer, db.ForeignKey('student.id'), nullable=False)

    sender = db.relationship('Student', foreign_keys=[sender_id], back_populates='recognitions_sent')
    receiver = db.relationship('Student', foreign_keys=[receiver_id], back_populates='recognitions_received')
    endorsements = db.relationship('Endorsement', back_populates='recognition', lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "message": self.message,
            "credits": self.credits,
            "timestamp": self.timestamp.isoformat(),
            "sender_id": self.sender_id,
            "receiver_id": self.receiver_id
        }

class Endorsement(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    endorser_id = db.Column(db.Integer, db.ForeignKey('student.id'), nullable=False)
    recognition_id = db.Column(db.Integer, db.ForeignKey('recognition.id'), nullable=False)
    timestamp = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    endorser = db.relationship('Student', back_populates='endorsements_given')
    recognition = db.relationship('Recognition', back_populates='endorsements')

    __table_args__ = (db.UniqueConstraint('endorser_id', 'recognition_id', name='uq_endorsement'),)

    def to_dict(self):
        return {
            "id": self.id,
            "endorser_id": self.endorser_id,
            "recognition_id": self.recognition_id,
            "timestamp": self.timestamp.isoformat()
        }
