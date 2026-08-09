document.addEventListener("DOMContentLoaded", () => {
    // 1. Initialize Editor
    const editor = CodeMirror.fromTextArea(document.getElementById("code-editor"), {
        mode: "text/x-csrc",
        theme: "dracula",
        lineNumbers: true,
        indentUnit: 4,
        matchBrackets: true,
        autoCloseBrackets: true
    });

    editor.setValue(`int main() {\n    int a = 5;\n    int b = 10;\n    int result = a + b;\n    return result;\n}`);

    // 2. Tab Switching
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');

    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));
            
            btn.classList.add('active');
            document.getElementById(btn.dataset.target).classList.add('active');
        });
    });

    // 3. Clear Button
    document.getElementById('btn-clear').addEventListener('click', () => {
        editor.setValue('');
    });

    // 4. Compile API Call
    const compileBtn = document.getElementById('btn-compile');
    
    compileBtn.addEventListener('click', async () => {
        const code = editor.getValue();
        const badge = document.getElementById('status-badge');
        
        badge.className = 'badge compiling';
        badge.innerText = 'Compiling...';
        
        const formData = new FormData();
        formData.append('code', code);
        
        try {
            const response = await fetch('/api/compile/', {
                method: 'POST',
                body: formData
            });
            
            const result = await response.json();
            
            document.getElementById('output-text').innerText = result.output || 'No output.';
            document.getElementById('tokens-text').innerText = result.tokens || 'No tokens generated.';
            document.getElementById('errors-text').innerText = result.errors || 'No errors.';
            
            if (result.status === 'success') {
                badge.className = 'badge success';
                badge.innerText = 'Success';
                document.querySelector('[data-target="out-compiler"]').click();
            } else {
                badge.className = 'badge error';
                badge.innerText = 'Failed';
                document.querySelector('[data-target="out-errors"]').click();
            }
        } catch (error) {
            badge.className = 'badge error';
            badge.innerText = 'Server Error';
            document.getElementById('errors-text').innerText = 'Backend connection failed.';
        }
    });
});