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
        // 파일 존재 여부 먼저 확인
        try {
            await fs.access(METADATA_FILE);
        } catch {
            console.log('Metadata file not found, creating empty one');
            await fs.writeFile(METADATA_FILE, JSON.stringify([], null, 2));
            return res.json([]);
        }

        const metadata = await fs.readFile(METADATA_FILE, 'utf8');
        console.log('Raw metadata content:', metadata); // 디버깅용 로그

        const questionSets = JSON.parse(metadata);
        console.log(`Retrieved ${questionSets.length} question sets`);
        res.json(questionSets);
    } catch (error) {
        console.error('Detailed error in /api/question-sets:', error);
        res.status(500).json({ 
            error: 'Failed to fetch question sets',
            details: error.message 
        });
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

const privacyPolicyHTML = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AISnapStudy Privacy Policy</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2 {
            color: #333;
        }
        .section {
            margin-bottom: 30px;
        }
    </style>
</head>
<body>
    <h1>AISnapStudy Privacy Policy</h1>
    <p>Last updated: ${new Date().toISOString().split('T')[0]}</p>

    <div class="section">
        <h2>1. Data Usage</h2>
        <p>AISnapStudy is designed with privacy in mind:</p>
        <ul>
            <li>Images uploaded for question generation are processed immediately and are not stored</li>
            <li>All study progress and statistics are stored locally on your device only</li>
            <li>No personal information is collected or stored on our servers</li>
        </ul>
    </div>

    <div class="section">
        <h2>2. Image Processing</h2>
        <p>When you take a photo or upload an image:</p>
        <ul>
            <li>The image is temporarily processed to generate study questions</li>
            <li>Images are immediately deleted after processing</li>
            <li>No images are stored or retained</li>
        </ul>
    </div>

    <div class="section">
        <h2>3. Local Storage</h2>
        <p>All app data, including:</p>
        <ul>
            <li>Generated questions</li>
            <li>Study progress</li>
            <li>Performance statistics</li>
        </ul>
        <p>is stored locally on your device and is not transmitted to our servers.</p>
    </div>

    <div class="section">
        <h2>4. Subscription</h2>
        <p>All purchases and subscriptions are handled directly through Apple's App Store. We do not collect or store any payment information.</p>
    </div>

    <div class="section">
        <h2>5. Third-Party Services</h2>
        <p>We use OpenAI's API for question generation. Images are temporarily processed through their service following their privacy standards.</p>
    </div>

    <div class="section">
        <h2>6. Contact Us</h2>
        <p>If you have any questions about this Privacy Policy, please contact us at: kish1919@gmail.com </p>
    </div>
</body>
</html>
`;

// Privacy Policy 엔드포인트 추가
app.get('/privacy-policy', (req, res) => {
    res.setHeader('Content-Type', 'text/html');
    res.send(privacyPolicyHTML);
});


// server.js에 추가

const supportPageHTML = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AISnapStudy Support</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2 {
            color: #333;
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            background: #f9f9f9;
            border-radius: 8px;
        }
        .question {
            font-weight: bold;
            color: #2c5282;
            margin-bottom: 10px;
        }
        .answer {
            margin-bottom: 20px;
        }
        .contact-button {
            display: inline-block;
            padding: 10px 20px;
            background: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <h1>AISnapStudy Support</h1>

    <div class="section">
        <h2>Frequently Asked Questions</h2>
        
        <div class="question">Q: How do I create questions from my textbook?</div>
        <div class="answer">
            A: Simply tap the camera button, take a photo of your textbook page, and our AI will generate study questions instantly.
        </div>

        <div class="question">Q: What types of questions can be generated?</div>
        <div class="answer">
            A: AISnapStudy generates multiple-choice and true/false questions, complete with explanations and hints.
        </div>

        <div class="question">Q: How can I access my saved questions?</div>
        <div class="answer">
            A: Go to the Review tab and tap on "Saved Questions" to access all your bookmarked questions.
        </div>

        <div class="question">Q: What's included in the Premium subscription?</div>
        <div class="answer">
            A: Premium includes:
            <ul>
                <li>Generate up to 30 question sets daily</li>
                <li>Unlimited question set downloads</li>
                <li>Ad-free experience</li>
                <li>Advanced statistics</li>
            </ul>
        </div>
    </div>

    <div class="section">
        <h2>Common Issues</h2>
        
        <div class="question">Camera not working?</div>
        <div class="answer">
            Please ensure you've granted camera permissions to AISnapStudy in your device settings:
            Settings > Privacy > Camera > AISnapStudy
        </div>

        <div class="question">Questions not generating?</div>
        <div class="answer">
            Check your internet connection and ensure your image is clear and well-lit.
        </div>
    </div>

    <div class="section">
        <h2>Contact Support</h2>
        <p>We're here to help! Contact us through any of these channels:</p>
        
        <p><strong>Email:</strong> <a href="mailto:kish1919@gmail.com">kish1919@gmail.com</a></p>
        
        <p><strong>Response Time:</strong> We typically respond within 24 hours.</p>
    </div>

    <div class="section">
        <h2>Subscription Management</h2>
        <p>To manage your subscription:</p>
        <ol>
            <li>Open iPhone Settings</li>
            <li>Tap your Apple ID at the top</li>
            <li>Tap Subscriptions</li>
            <li>Find AISnapStudy in the list</li>
            <li>Manage your subscription options</li>
        </ol>
    </div>
</body>
</html>
`;

// Support 페이지 엔드포인트 추가
app.get('/support', (req, res) => {
    res.setHeader('Content-Type', 'text/html');
    res.send(supportPageHTML);
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
