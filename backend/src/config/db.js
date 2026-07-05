const mongoose = require('mongoose');
const Doctor = require('../models/Doctor');
const Lead = require('../models/Lead');
const Interaction = require('../models/Interaction');

const seedData = async () => {
  try {
    const doctorCount = await Doctor.countDocuments();
    if (doctorCount === 0) {
      console.log('Seeding doctors...');
      await Doctor.insertMany([
        {
          _id: '6a224fb319a418a64262ba60',
          name: 'Dr Chandramouli S',
          specialty: 'General Physician',
          region: 'Visakhapatnam',
          mobile: '+91 88972 08298',
          email: 'samathamcm@gmail.com',
          status: 'Saved',
          availableFrom: '9:00 AM',
          availableTo: '5:00 PM',
        },
        {
          _id: '6a2317f2582fb8e94a173ad6',
          name: 'Dr Harshith Sharma',
          specialty: 'Cardiologist',
          region: 'Hyderabad',
          mobile: '+91 94943 84045',
          email: 'harshith.sharma@cardiohealth.in',
          status: 'MedRep Launched',
          availableFrom: '10:00 AM',
          availableTo: '6:00 PM',
        },
        {
          _id: '6a239b7699d2884d26be5438',
          name: 'Dr Tota Deepa Swamy',
          specialty: 'Pediatrician',
          region: 'Bangalore',
          mobile: '+91 91600 11180',
          email: 'deepa.swamy@pediatriccare.org',
          status: 'Call Scheduled',
          availableFrom: '11:00 AM',
          availableTo: '4:00 PM',
        },
        {
          _id: '6a239c3b99d2884d26be5439',
          name: 'Dr Roopa Reddy',
          specialty: 'Dermatologist',
          region: 'Chennai',
          mobile: '+91 91600 22280',
          email: 'roopa.reddy@skincare.in',
          status: 'MedRep Launched',
          availableFrom: '9:30 AM',
          availableTo: '3:30 PM',
        }
      ]);
      console.log('Doctors seeded.');
    }

    const leadCount = await Lead.countDocuments();
    if (leadCount === 0) {
      console.log('Seeding leads...');
      await Lead.insertMany([
        {
          doctor_name: 'Dr. Alice Smith',
          query: 'Requested samples of Paracetamol 500mg but only received 250mg.',
          status: 'Pending',
        },
        {
          doctor_name: 'Dr. Bob Jones',
          query: 'The login credentials for the portal are not working.',
          status: 'In Progress',
          assigned_to: 'Tech Alex',
        },
        {
          doctor_name: 'Dr. Charlie Brown',
          query: 'Need detailed literature on the new cardiovascular drug efficacy.',
          status: 'Pending',
        },
        {
          doctor_name: 'Dr. Diana Prince',
          query: "Delivery of last week's order is delayed by 3 days.",
          status: 'Resolved',
          assigned_to: 'Tech Sarah',
        }
      ]);
      console.log('Leads seeded.');
    }

    const interactionCount = await Interaction.countDocuments();
    if (interactionCount === 0) {
      console.log('Seeding interactions...');
      await Interaction.insertMany([
        {
          doctor: '6a2317f2582fb8e94a173ad6',
          notes: 'Discussed cardiovascular drug efficacy and provided patient samples.',
          type: 'In-person',
          date: new Date(Date.now() - 24 * 60 * 60 * 1000),
        },
        {
          doctor: '6a239c3b99d2884d26be5439',
          notes: 'Walked through custom dosage guidelines via tele-call.',
          type: 'Virtual',
          date: new Date(Date.now() - 3 * 60 * 60 * 1000),
        }
      ]);
      console.log('Interactions seeded.');
    }
  } catch (error) {
    console.error(`Seeding error: ${error.message}`);
  }
};

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    await seedData();
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
