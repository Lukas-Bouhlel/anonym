'use strict';

const fs = require('fs');
const admin = require('firebase-admin');
const { Op } = require('sequelize');
const { DevicePushToken } = require('../models');

let firebaseInitialized = false;
let firebaseEnabled = false;

const INVALID_TOKEN_ERROR_CODES = new Set([
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
    'messaging/invalid-argument'
]);

const initFirebase = () => {
    if (firebaseInitialized) {
        return firebaseEnabled;
    }

    firebaseInitialized = true;

    try {
        if (!admin.apps.length) {
            const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
            const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

            if (serviceAccountJson) {
                const serviceAccount = JSON.parse(serviceAccountJson);
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount)
                });
            } else if (serviceAccountPath) {
                const fileContent = fs.readFileSync(serviceAccountPath, 'utf8');
                const serviceAccount = JSON.parse(fileContent);
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount)
                });
            } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
                admin.initializeApp({
                    credential: admin.credential.applicationDefault()
                });
            } else {
                firebaseEnabled = false;
                return false;
            }
        }

        firebaseEnabled = true;
        return true;
    } catch (error) {
        console.error('Failed to initialize Firebase Admin SDK:', error.message);
        firebaseEnabled = false;
        return false;
    }
};

const deactivateTokens = async (tokens) => {
    if (!tokens || tokens.length === 0) return;
    await DevicePushToken.update(
        { is_active: false },
        { where: { token: { [Op.in]: tokens } } }
    );
};

const sendPushToUsers = async ({
    userIds,
    data,
    excludeUserId = null
}) => {
    try {
        if (!Array.isArray(userIds) || userIds.length === 0) return;
        if (!initFirebase()) return;

        const uniqueUserIds = [...new Set(
            userIds
                .map((id) => Number(id))
                .filter((id) => Number.isInteger(id) && id > 0 && id !== Number(excludeUserId))
        )];

        if (uniqueUserIds.length === 0) return;

        const activeTokens = await DevicePushToken.findAll({
            where: {
                user_id: { [Op.in]: uniqueUserIds },
                is_active: true
            },
            attributes: ['token'],
            raw: true
        });

        const tokens = activeTokens.map((entry) => entry.token).filter(Boolean);
        if (tokens.length === 0) return;

        const response = await admin.messaging().sendEachForMulticast({
            tokens,
            data: Object.entries(data || {}).reduce((acc, [key, value]) => {
                if (value !== undefined && value !== null) {
                    acc[key] = String(value);
                }
                return acc;
            }, {})
        });

        const invalidTokens = [];
        response.responses.forEach((result, index) => {
            if (!result.success && result.error) {
                const errorCode = result.error.code;
                if (INVALID_TOKEN_ERROR_CODES.has(errorCode)) {
                    invalidTokens.push(tokens[index]);
                }
            }
        });

        if (invalidTokens.length > 0) {
            await deactivateTokens(invalidTokens);
        }
    } catch (error) {
        console.error('Failed to send push notifications:', error.message);
    }
};

module.exports = {
    sendPushToUsers
};
