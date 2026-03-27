- **改完就把下面的checkbox checked**

Mar27.2026 09:25
- [x] 编了opencv之后出现这个，这个是开了install-opencv才有的
    ```bash
    #19 163.7    creating: opencv-4.9.0/samples/wp8/OpenCVXaml/OpenCVXaml/Resources/
    #19 163.7   inflating: opencv-4.9.0/samples/wp8/OpenCVXaml/OpenCVXaml/Resources/AppResources.Designer.cs
    #19 163.7   inflating: opencv-4.9.0/samples/wp8/OpenCVXaml/OpenCVXaml/Resources/AppResources.resx
    #19 163.7   inflating: opencv-4.9.0/samples/wp8/readme.txt
    #19 163.8 /tmp/install_opencv.sh: line 38: cmake: command not found
    #19 163.8
    #19 163.8
    #19 163.8 ##########################################################
    #19 163.8 (3/4)OpenCV is installed, Done
    #19 163.8 ##########################################################
    #19 163.8
    #19 163.8

    ```

- [x] 还有这个，与是否opnecv/cuda无关
    ```bash
    #20 130.0 Setting up libpython3-dev:amd64 (3.12.3-0ubuntu2.1) ...
    #20 130.0 Setting up python3-dev (3.12.3-0ubuntu2.1) ...
    #20 130.0 Processing triggers for man-db (2.12.0-4build2) ...
    #20 130.9 pip 24.0 from /usr/lib/python3/dist-packages/pip (python 3.12)
    #20 131.2 error: externally-managed-environment
    #20 131.2
    #20 131.2 × This environment is externally managed
    #20 131.2 ╰─> To install Python packages system-wide, try apt install
    #20 131.2     python3-xyz, where xyz is the package you are trying to
    #20 131.2     install.
    #20 131.2
    #20 131.2     If you wish to install a non-Debian-packaged Python package,
    #20 131.2     create a virtual environment using python3 -m venv path/to/venv.
    #20 131.2     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 131.2     sure you have python3-full installed.
    #20 131.2
    #20 131.2     If you wish to install a non-Debian packaged Python application,
    #20 131.2     it may be easiest to use pipx install xyz, which will manage a
    #20 131.2     virtual environment for you. Make sure you have pipx installed.
    #20 131.2
    #20 131.2     See /usr/share/doc/python3.12/README.venv for more information.
    #20 131.2
    #20 131.2 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 131.2 hint: See PEP 668 for the detailed specification.
    #20 131.3 Retry installing cmake-format (0/3)
    #20 136.5 error: externally-managed-environment
    #20 136.5
    #20 136.5 × This environment is externally managed
    #20 136.5 ╰─> To install Python packages system-wide, try apt install
    #20 136.5     python3-xyz, where xyz is the package you are trying to
    #20 136.5     install.
    #20 136.5
    #20 136.5     If you wish to install a non-Debian-packaged Python package,
    #20 136.5     create a virtual environment using python3 -m venv path/to/venv.
    #20 136.5     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 136.5     sure you have python3-full installed.
    #20 136.5
    #20 136.5     If you wish to install a non-Debian packaged Python application,
    #20 136.5     it may be easiest to use pipx install xyz, which will manage a
    #20 136.5     virtual environment for you. Make sure you have pipx installed.
    #20 136.5
    #20 136.5     See /usr/share/doc/python3.12/README.venv for more information.
    #20 136.5
    #20 136.5 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 136.5 hint: See PEP 668 for the detailed specification.
    #20 136.6 Retry installing cmake-format (1/3)
    #20 141.8 error: externally-managed-environment
    #20 141.8
    #20 141.8 × This environment is externally managed
    #20 141.8 ╰─> To install Python packages system-wide, try apt install
    #20 141.8     python3-xyz, where xyz is the package you are trying to
    #20 141.8     install.
    #20 141.8
    #20 141.8     If you wish to install a non-Debian-packaged Python package,
    #20 141.8     create a virtual environment using python3 -m venv path/to/venv.
    #20 141.8     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 141.8     sure you have python3-full installed.
    #20 141.8
    #20 141.8     If you wish to install a non-Debian packaged Python application,
    #20 141.8     it may be easiest to use pipx install xyz, which will manage a
    #20 141.8     virtual environment for you. Make sure you have pipx installed.
    #20 141.8
    #20 141.8     See /usr/share/doc/python3.12/README.venv for more information.
    #20 141.8
    #20 141.8 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 141.8 hint: See PEP 668 for the detailed specification.
    #20 141.9 Retry installing cmake-format (2/3)
    #20 146.9 Warning: Failed to install cmake-format, continuing anyway...
    #20 147.1 error: externally-managed-environment
    #20 147.1
    #20 147.1 × This environment is externally managed
    #20 147.1 ╰─> To install Python packages system-wide, try apt install
    #20 147.1     python3-xyz, where xyz is the package you are trying to
    #20 147.1     install.
    #20 147.1
    #20 147.1     If you wish to install a non-Debian-packaged Python package,
    #20 147.1     create a virtual environment using python3 -m venv path/to/venv.
    #20 147.1     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 147.1     sure you have python3-full installed.
    #20 147.1
    #20 147.1     If you wish to install a non-Debian packaged Python application,
    #20 147.1     it may be easiest to use pipx install xyz, which will manage a
    #20 147.1     virtual environment for you. Make sure you have pipx installed.
    #20 147.1
    #20 147.1     See /usr/share/doc/python3.12/README.venv for more information.
    #20 147.1
    #20 147.1 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 147.1 hint: See PEP 668 for the detailed specification.
    #20 147.2 Retry installing pre-commit (0/3)
    #20 152.4 error: externally-managed-environment
    #20 152.4
    #20 152.4 × This environment is externally managed
    #20 152.4 ╰─> To install Python packages system-wide, try apt install
    #20 152.4     python3-xyz, where xyz is the package you are trying to
    #20 152.4     install.
    #20 152.4
    #20 152.4     If you wish to install a non-Debian-packaged Python package,
    #20 152.4     create a virtual environment using python3 -m venv path/to/venv.
    #20 152.4     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 152.4     sure you have python3-full installed.
    #20 152.4
    #20 152.4     If you wish to install a non-Debian packaged Python application,
    #20 152.4     it may be easiest to use pipx install xyz, which will manage a
    #20 152.4     virtual environment for you. Make sure you have pipx installed.
    #20 152.4
    #20 152.4     See /usr/share/doc/python3.12/README.venv for more information.
    #20 152.4
    #20 152.4 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 152.4 hint: See PEP 668 for the detailed specification.
    #20 152.5 Retry installing pre-commit (1/3)
    #20 157.7 error: externally-managed-environment
    #20 157.7
    #20 157.7 × This environment is externally managed
    #20 157.7 ╰─> To install Python packages system-wide, try apt install
    #20 157.7     python3-xyz, where xyz is the package you are trying to
    #20 157.7     install.
    #20 157.7
    #20 157.7     If you wish to install a non-Debian-packaged Python package,
    #20 157.7     create a virtual environment using python3 -m venv path/to/venv.
    #20 157.7     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 157.7     sure you have python3-full installed.
    #20 157.7
    #20 157.7     If you wish to install a non-Debian packaged Python application,
    #20 157.7     it may be easiest to use pipx install xyz, which will manage a
    #20 157.7     virtual environment for you. Make sure you have pipx installed.
    #20 157.7
    #20 157.7     See /usr/share/doc/python3.12/README.venv for more information.
    #20 157.7
    #20 157.7 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 157.7 hint: See PEP 668 for the detailed specification.
    #20 157.8 Retry installing pre-commit (2/3)
    #20 162.8 Warning: Failed to install pre-commit, continuing anyway...
    #20 162.8
    #20 162.8
    #20 162.8 ##########################################################
    #20 162.8 (4/4)Dev Tools are installed, Done
    #20 162.8 ##########################################################
    #20 162.8
    #20 162.8
    #20 DONE 162.9s

    #21 [stage_2nd_tools 10/12] RUN chmod +x /usr/local/bin/gitlfs_tracker.sh
    #21 DONE 0.1s

    #22 [stage_2nd_tools 11/12] RUN rm -f /tmp/install_*.sh &&     rm -f /tmp/tool_versions.conf
    #22 DONE 0.1s


    ```
- [x] 这个也是不论是否开opencv/cuda，都有的
    ```bash
    #68 [stage_5th_final  6/10] RUN set -ex &&     /usr/local/bin/setup_workspace.sh
    #68 0.074 + /usr/local/bin/setup_workspace.sh
    #68 0.075
    #68 0.075 Starting workspace setup...
    #68 0.075 Initializing workspace structure...
    #68 0.075 Creating directory:
    #68 0.075 ERROR: Directory path is empty
    #68 ERROR: process "/bin/bash -c set -ex &&     /usr/local/bin/setup_workspace.sh" did not complete successfully: exit code: 1
    ------
    > [stage_5th_final  6/10] RUN set -ex &&     /usr/local/bin/setup_workspace.sh:
    0.074 + /usr/local/bin/setup_workspace.sh
    0.075
    0.075 Starting workspace setup...
    0.075 Initializing workspace structure...
    0.075 Creating directory:
    0.075 ERROR: Directory path is empty
    ------

    4 warnings found (use docker --debug to expand):
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "DEV_USER_PASSWORD") (line 47)
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "DEV_USER_ROOT_PASSWORD") (line 48)
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "SAMBA_PRIVATE_ACCOUNT_PASSWORD") (line 125)
    - UndefinedVar: Usage of undefined variable '$USE_NVIDIA_GPU' (line 152)
    Dockerfile:529
    --------------------
    528 |     # Setup workspace and permissions
    529 | >>> RUN set -ex && \
    530 | >>>     /usr/local/bin/setup_workspace.sh
    531 |
    --------------------
    ERROR: failed to build: failed to solve: process "/bin/bash -c set -ex &&     /usr/local/bin/setup_workspace.sh" did not complete successfully: exit code: 1
    In /mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git/docker/dev-env-clientside/build.sh, Docker build failed with exit status: 1
    Error: Failed to build clientside image
    james@Anastasia:/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git$


    ```


Mar27.2026 09:10
- [x] 运行出现
    ```bash
    $ ./harbor
    Build process started at:
    ###################################
    #   Fri Mar27.2026 09:03:39
    ###################################

    Now we have below platforms:

    ```
    请解决

Mar27.2026 08:40
- [x] 继续完成HarborPilot.git/docs/architecture/2-progress/Mar27.2026-RestWork里的剩余工作，做完后验证（包括请我手动验证，告诉我验证方法和项目是什么），然后确认做好，提醒我确认是否删除HarborPilot.git/docs/architecture/2-progress/Mar27.2026-RestWork文档，然后你commit

Mar26.2026 23:00
- [x] Fix README.md: all `doc/` references need updating to `docs/` after directory rename
- [x] Evaluate: should `docker/libs/iv_scripts/setup_base.sh` be deleted or merged into stage_1 version? → **Deleted** (fully superseded by stage_1 version)
- [x] Evaluate: should `docker/libs/ii_dockerfile_modules/*.df` be deleted (never used by current Dockerfile)? → **Deleted** (entire `docker/libs/` removed)
- [x] `docker-compose.yaml` in project_handover still has hardcoded values — should use `${VAR}` from `.env` → **Done** (8 values now configurable via defaults)
