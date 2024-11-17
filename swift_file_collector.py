import os

def collect_swift_files(directory, output_file):
    """
    현재 디렉토리의 하위에 있는 모든 Swift 파일 (CoreData 폴더 내부 제외)를 찾아 내용을 하나의 텍스트 파일에 저장합니다.
    
    Parameters:
    directory (str): 검색할 디렉토리 경로
    output_file (str): 결과를 저장할 텍스트 파일 경로
    """
    swift_files = []
    
    for root, dirs, files in os.walk(directory):
        # CoreData 폴더는 제외
        if 'CoreData' in root:
            continue
        
        for file in files:
            if file.endswith('.swift'):
                swift_files.append(os.path.join(root, file))
    
    with open(output_file, 'w', encoding='utf-8') as f:
        for swift_file in swift_files:
            f.write(f'// {swift_file}\n\n')
            with open(swift_file, 'r', encoding='utf-8') as swift_f:
                f.write(swift_f.read())
            f.write('\n\n')
    
    print(f'Swift files collected and saved to {output_file}')

# 사용 예시
collect_swift_files('.', 'swift_files.txt')