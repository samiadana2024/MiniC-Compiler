import os
import subprocess
import tempfile

from django.conf import settings
from django.http import JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt


def index(request):
    return render(request, "compiler/index.html")

@csrf_exempt
def compile_code(request):
    if request.method == 'POST':
        code = request.POST.get('code', '')

        # 1. Write user's code to a temporary C file
        with tempfile.NamedTemporaryFile(
            mode='w',
            suffix='.c',
            delete=False
        ) as temp_file:
            temp_file.write(code)
            temp_file_path = temp_file.name

        # 2. Path to compiler engine
        compiler_exe = os.path.abspath(
      os.path.join(
        settings.BASE_DIR,
        "compiler_engine",
        "compiler_engine"
    )
)

        try:
            # 3. Run compiler engine
            process = subprocess.run(
                [compiler_exe, temp_file_path],
                capture_output=True,
                text=True,
                timeout=5,
                cwd=os.path.dirname(compiler_exe)
            )

            stdout = process.stdout
            stderr = process.stderr

            # 4. Separate tokens and program output
            tokens = []
            output_msg = []

            for line in stdout.splitlines():

                if line.startswith('TOKEN:'):
                    tokens.append(
                        line.replace('TOKEN: ', '')
                    )

                elif line.startswith('PROGRAM_OUTPUT:'):
                    output_msg.append(
                        line.replace(
                            'PROGRAM_OUTPUT:',
                            ''
                        ).strip()
                    )

                elif line.strip() and line != 'COMPILATION_SUCCESS':
                    output_msg.append(line)

            # 5. Return result to frontend
            return JsonResponse({
                'status': (
                    'success'
                    if process.returncode == 0
                    else 'error'
                ),
                'output': '\n'.join(output_msg),
                'tokens': '\n'.join(tokens),
                'errors': stderr
            })

        except subprocess.TimeoutExpired:
            return JsonResponse({
                'status': 'error',
                'errors': 'Timeout Error: Code execution took too long.'
            })

        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'errors': str(e)
            })

        finally:
            # 6. Delete temporary file
            if os.path.exists(temp_file_path):
                os.remove(temp_file_path)

    return JsonResponse(
        {'error': 'Invalid request'},
        status=400
    )