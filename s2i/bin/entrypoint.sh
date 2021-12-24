#!/bin/bash

eval "$(conda shell.bash hook)"

if [ -e /opt/app-root/src/.assembled ]; then
    project_command=${CMD:-default}
    env_spec=$(python -c "from anaconda_project.project import Project;print(Project('.').command_for_name('${project_command}').default_env_spec_name)")
    conda activate ./envs/${env_spec}
else
    conda activate base
fi

exec tini -g -- "$@"