// server.js 파일
require('dotenv').config();

// 환경 변수 로딩 확인 로그 추가
console.log('Environment Check:');
console.log('- PORT:', process.env.PORT);
console.log('- API Key exists:', !!process.env.OPENAI_API_KEY);
console.log('- API Key length:', process.env.OPENAI_API_KEY?.length);

// dotenv 설정 확인 로그 추가
console.log('Loaded environment variables:', {
    PORT: process.env.PORT,
    OPENAI_API_KEY_EXISTS: !!process.env.OPENAI_API_KEY,
    OPENAI_API_KEY_LENGTH: process.env.OPENAI_API_KEY?.length
});

const express = require('express');
const cors = require('cors');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const fs = require('fs');
const app = express();


// 미들웨어 설정
app.use(express.json());
app.use(cors());

// 환경변수 확인
if (!process.env.OPENAI_API_KEY) {
    console.error('OPENAI_API_KEY is not set in environment variables');
    process.exit(1);
}

// 기본 경로
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK' });
});

app.get('/api/get-api-key', (req, res) => {
    // API Key 로깅 추가
    console.log('Current API Key:', process.env.OPENAI_API_KEY);
    
    const apiKey = process.env.OPENAI_API_KEY?.trim();
    if (!apiKey) {
        console.error('API Key not found or empty');
        return res.status(500).json({ error: 'API key not configured' });
    }
    
    // 응답 로깅
    console.log('Sending API Key (first 10 chars):', apiKey.substring(0, 10) + '...');
    res.json({ apiKey });
});

app.post('/api/openai/chat', async (req, res) => {
    try {
        // API Key 확인
        console.log('Using API Key (first 10 chars):', process.env.OPENAI_API_KEY.substring(0, 10) + '...');
        
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.OPENAI_API_KEY.trim()}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(req.body)
        });
        
        // 응답 로깅
        console.log('OpenAI Response Status:', response.status);
        const data = await response.json();
        
        if (!response.ok) {
            console.error('OpenAI Error:', data);
            throw new Error(data.error?.message || 'OpenAI API 요청 실패');
        }
        
        res.json(data);
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: error.message });
    }
});

// 서버 시작 (nginx가 SSL을 처리하므로 HTTP로 시작)
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
