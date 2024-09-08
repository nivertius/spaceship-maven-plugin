#
# Maven Project
#
# Reads Maven project version from current directory and displays artifactId and version
# Link: https://maven.apache.org/

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_MAVEN_VERSION_SHOW="${SPACESHIP_MAVEN_VERSION_SHOW=true}"
SPACESHIP_MAVEN_VERSION_ASYNC="${SPACESHIP_MAVEN_VERSION_ASYNC=true}"
SPACESHIP_MAVEN_VERSION_PREFIX="${SPACESHIP_MAVEN_VERSION_PREFIX="at "}"
SPACESHIP_MAVEN_VERSION_SUFFIX="${SPACESHIP_MAVEN_VERSION_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_MAVEN_VERSION_SYMBOL="${SPACESHIP_MAVEN_VERSION_SYMBOL="🪶"}"
SPACESHIP_MAVEN_VERSION_COLOR="${SPACESHIP_MAVEN_VERSION_COLOR="yellow"}"

SPACESHIP_MAVEN_VERSION_SHORTEN_SNAPSHOT="${SPACESHIP_MAVEN_VERSION_SHORTEN_SNAPSHOT=true}"
SPACESHIP_MAVEN_VERSION_DYNAMIC="${SPACESHIP_MAVEN_VERSION_DYNAMIC=true}"
if [ -z "$SPACESHIP_MAVEN_VERSION_DYNAMIC_VERSIONS" ]; then
  SPACESHIP_MAVEN_VERSION_DYNAMIC_VERSIONS=("0")
fi

SPACESHIP_MAVEN_ARTIFACT_SHOW="${SPACESHIP_MAVEN_ARTIFACT_SHOW=dir-different}"
SPACESHIP_MAVEN_ARTIFACT_ASYNC="${SPACESHIP_MAVEN_ARTIFACT_ASYNC=true}"
SPACESHIP_MAVEN_ARTIFACT_PREFIX="${SPACESHIP_MAVEN_ARTIFACT_PREFIX="on "}"
SPACESHIP_MAVEN_ARTIFACT_SUFFIX="${SPACESHIP_MAVEN_ARTIFACT_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_MAVEN_ARTIFACT_SYMBOL="${SPACESHIP_MAVEN_ARTIFACT_SYMBOL="📦"}"
SPACESHIP_MAVEN_ARTIFACT_COLOR="${SPACESHIP_MAVEN_ARTIFACT_COLOR="yellow"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Show current version of maven project.
spaceship_maven_version() {
  [[ $SPACESHIP_MAVEN_VERSION_SHOW == false ]] && return
  spaceship::exists xmllint || return

  local maven_project="$(spaceship::upsearch 'pom.xml')"
  [[ -n "$maven_project" ]] || return

  local maven_version
  local parts=($(echo "cat /*[local-name()='project']/*[local-name()='version']/text()\n" \
	"cat /*[local-name()='project']/*[local-name()='parent']/*[local-name()='version']/text()\n" |
    xmllint --shell $maven_project 2>/dev/null |
    sed '/^\/ >/d'))
  if [[ "${#parts}" > 0 ]]; then
    maven_version="${parts[1]}"
  else
    maven_version="pom!"
  fi

  if [[ $SPACESHIP_MAVEN_VERSION_DYNAMIC != false ]]; then
    local need_dynamic=false
    for candidate in "${SPACESHIP_MAVEN_VERSION_DYNAMIC_VERSIONS[@]}"; do
      if [[ $maven_version == $candidate ]]; then
        need_dynamic=true
      fi
    done
    if [[ $need_dynamic != false ]]; then
      local maven_exe=$(spaceship::upsearch mvnw)
      if [[ -z $maven_exe ]] && spaceship::exists mvn; then
        maven_exe="mvn"
      fi
      if [[ -n $maven_exe ]]; then
        maven_version=$($maven_exe help:evaluate -q -DforceStdout -D"expression=project.version" 2>/dev/null | sed 's/\x1B.*$//g')
      fi
    fi
  fi

  if [[ $SPACESHIP_MAVEN_VERSION_SHORTEN_SNAPSHOT != false ]]; then
    maven_version=${maven_version/%-SNAPSHOT/+}
  fi

  spaceship::section::v4 \
    --color "$SPACESHIP_MAVEN_VERSION_COLOR" \
    --prefix "$SPACESHIP_MAVEN_VERSION_PREFIX" \
    --suffix "$SPACESHIP_MAVEN_VERSION_SUFFIX" \
    --symbol "$SPACESHIP_MAVEN_VERSION_SYMBOL" \
    "$maven_version"
}

# Show current artifact of maven project.
spaceship_maven_artifact() {
  [[ $SPACESHIP_MAVEN_ARTIFACT_SHOW == false ]] && return
  spaceship::exists xmllint || return

  local maven_project="$(spaceship::upsearch 'pom.xml')"
  [[ -n "$maven_project" ]] || return

  local maven_artifact
  local parts=($(echo "cat /*[local-name()='project']/*[local-name()='artifactId']/text()\n" |
    xmllint --shell $maven_project 2>/dev/null |
    sed '/^\/ >/d'))
  if [[ "${#parts}" > 0 ]]; then
    maven_artifact="${parts[1]}"
  else
    maven_artifact="pom!"
  fi

  local containing_directory=$(basename $(dirname $maven_project))

  [[ $SPACESHIP_MAVEN_ARTIFACT_SHOW == dir-different && $maven_artifact == "$containing_directory" ]] && return

  spaceship::section::v4 \
    --color "$SPACESHIP_MAVEN_ARTIFACT_COLOR" \
    --prefix "$SPACESHIP_MAVEN_ARTIFACT_PREFIX" \
    --suffix "$SPACESHIP_MAVEN_ARTIFACT_SUFFIX" \
    --symbol "$SPACESHIP_MAVEN_ARTIFACT_SYMBOL" \
    "$maven_artifact"
}

