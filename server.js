require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const fs = require('fs').promises;
const path = require('path');
const lockfile = require('proper-lockfile');

// 환경 변수 로딩 확인 로그
console.log('Environment Check:', {
    PORT: process.env.PORT,
    OPENAI_API_KEY_EXISTS: !!process.env.OPENAI_API_KEY,
    OPENAI_API_KEY_LENGTH: process.env.OPENAI_API_KEY?.length
});

const app = express();

// 미들웨어 설정
app.use(express.json());
app.use(cors());

// 질문 세트 관련 상수
const QUESTION_SETS_DIR = path.join(__dirname, 'question-sets');
const METADATA_FILE = path.join(QUESTION_SETS_DIR, 'metadata.json');

// 환경변수 확인
if (!process.env.OPENAI_API_KEY) {
    console.error('OPENAI_API_KEY is not set in environment variables');
    process.exit(1);
}

// 기존 엔드포인트들
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK' });
});

app.get('/api/get-api-key', (req, res) => {
    const apiKey = process.env.OPENAI_API_KEY?.trim();
    if (!apiKey) {
        console.error('API Key not found or empty');
        return res.status(500).json({ error: 'API key not configured' });
    }
    
    console.log('Sending API Key (first 10 chars):', apiKey.substring(0, 10) + '...');
    res.json({ apiKey });
});

app.post('/api/openai/chat', async (req, res) => {
    try {
        console.log('Using API Key (first 10 chars):', process.env.OPENAI_API_KEY.substring(0, 10) + '...');
        
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.OPENAI_API_KEY.trim()}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(req.body)
        });
        
        console.log('OpenAI Response Status:', response.status);
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error?.message || 'OpenAI API 요청 실패');
        }
        
        res.json(data);
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: error.message });
    }
});

// 새로운 질문 세트 관련 엔드포인트들

// 모든 질문 세트 메타데이터 조회
app.get('/api/question-sets', async (req, res) => {
    try {
        const metadata = await fs.readFile(METADATA_FILE, 'utf8');
        const questionSets = JSON.parse(metadata);
        console.log(`Retrieved ${questionSets.length} question sets`);
        res.json(questionSets);
    } catch (error) {
        console.error('Error reading question sets:', error);
        res.status(500).json({ error: 'Failed to fetch question sets' });
    }
});

// 특정 질문 세트 다운로드
app.get('/api/question-sets/:id', async (req, res) => {
    let release;
    try {
        const { id } = req.params;
        const filePath = path.join(QUESTION_SETS_DIR, `${id}.json`);
        
        // 파일 존재 여부 확인
        try {
            await fs.access(filePath);
        } catch {
            return res.status(404).json({ error: 'Question set not found' });
        }

        // 메타데이터 파일에 대한 락 획득
        release = await lockfile.lock(METADATA_FILE, {
            retries: 5,
            retryWait: 100
        });

        // 메타데이터 업데이트
        const metadataContent = await fs.readFile(METADATA_FILE, 'utf8');
        const metadata = JSON.parse(metadataContent);
        const setIndex = metadata.findIndex(set => set.id === id);
        
        if (setIndex !== -1) {
            metadata[setIndex].downloadCount = (metadata[setIndex].downloadCount || 0) + 1;
            await fs.writeFile(METADATA_FILE, JSON.stringify(metadata, null, 2));
        }

        // 질문 세트 읽기
        const questionSet = await fs.readFile(filePath, 'utf8');
        console.log(`Downloaded question set: ${id}`);
        
        res.json(JSON.parse(questionSet));
    } catch (error) {
        console.error('Error downloading question set:', error);
        res.status(500).json({ error: 'Failed to download question set' });
    } finally {
        // 락 해제
        if (release) {
            try {
                await release();
            } catch (error) {
                console.error('Error releasing lock:', error);
            }
        }
    }
});

// 카테고리별 질문 세트 조회
app.get('/api/question-sets/category/:category', async (req, res) => {
    try {
        const { category } = req.params;
        const metadata = JSON.parse(await fs.readFile(METADATA_FILE, 'utf8'));
        const filteredSets = metadata.filter(set => set.category === category);
        console.log(`Found ${filteredSets.length} sets in category: ${category}`);
        res.json(filteredSets);
    } catch (error) {
        console.error('Error fetching category:', error);
        res.status(500).json({ error: 'Failed to fetch category' });
    }
});

// 인기 질문 세트 조회
app.get('/api/question-sets/featured/popular', async (req, res) => {
    try {
        const metadata = JSON.parse(await fs.readFile(METADATA_FILE, 'utf8'));
        const popularSets = metadata
            .sort((a, b) => (b.downloadCount || 0) - (a.downloadCount || 0))
            .slice(0, 10);
        console.log(`Retrieved ${popularSets.length} popular sets`);
        res.json(popularSets);
    } catch (error) {
        console.error('Error fetching popular sets:', error);
        res.status(500).json({ error: 'Failed to fetch popular sets' });
    }
});

// 서버 초기화 함수
async function initializeServer() {
    try {
        // 질문 세트 디렉토리 생성
        await fs.mkdir(QUESTION_SETS_DIR, { recursive: true });
        
        // 메타데이터 파일이 없으면 생성
        try {
            await fs.access(METADATA_FILE);
        } catch {
            await fs.writeFile(METADATA_FILE, JSON.stringify([], null, 2));
            console.log('Created empty metadata file');
        }
        
        console.log('Server initialized successfully');
    } catch (error) {
        console.error('Error initializing server:', error);
        process.exit(1);
    }
}

// 서버 시작
const PORT = process.env.PORT || 3000;
initializeServer().then(() => {
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
});