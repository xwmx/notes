#!/usr/bin/env bats

load test_helper

# error handling ##############################################################

@test "'rename folder/<filename>' with invalid filename returns with error and message." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                  \
      --title   "Sample Title"                                  \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                 \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
    [[   -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                               ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                ]]
  }

  run "${_NB}" rename           \
    "Example Folder/not-valid"  \
    "Example Folder/example.md" \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 1:

  [[ ${status} -eq 1 ]]

  # Does not rename file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
  [[   -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                               ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                ]]

  # Does not create git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)"   ]]
  do
    sleep 1
  done
  git log | grep -v -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ Not\ found:               ]]
  [[ "${output}" =~ Example\ Folder/not-valid ]]
}

# <filename> ##################################################################

@test "'rename notebook:folder/folder/<filename>' renames across notebooks and levels without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
    [[ ! -e "${NB_DIR}/one/example.md"                                              ]]
    [[ ! -e "${NB_DIR}/one/Example Folder/example.md"                               ]]
    [[ ! -e "${NB_DIR}/two/example.md"                                              ]]
    [[ ! -e "${NB_DIR}/two/Example Folder/example.md"                               ]]

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks add "two"

    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]
  }

  run "${_NB}" rename                                             \
    "home:Example Folder/Sample Folder/Example File.bookmark.md"  \
    "two:Example Folder/example.md"                              \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commits:

  cd "${NB_DIR}/home" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Delete:'

  cd "${NB_DIR}/two" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Add:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
  [[ ! -e "${NB_DIR}/one/example.md"                                              ]]
  [[ ! -e "${NB_DIR}/one/Example Folder/example.md"                               ]]
  [[ ! -e "${NB_DIR}/two/example.md"                                              ]]
  [[   -e "${NB_DIR}/two/Example Folder/example.md"                               ]]

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ moved\ to                                                           ]]
  [[ "${output}" =~ two:Example\\\ Folder/example.md                                    ]]
}

@test "'rename folder/<filename>' renames properly without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                  \
      --title   "Sample Title"                                  \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                 \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
    [[   -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                               ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                ]]
  }

  run "${_NB}" rename                         \
    "Example Folder/Example File.bookmark.md" \
    "Example Folder/example.md"               \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                               ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ Example\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                            ]]
  [[ "${output}" =~ Example\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ renamed\ to                                   ]]
  [[ "${output}" =~ Example\\\ Folder/example.md                  ]]
}

@test "'rename folder/folder/<filename>' renames properly on same level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]
  }

  run "${_NB}" rename                                       \
    "Example Folder/Sample Folder/Example File.bookmark.md" \
    "Example Folder/Sample Folder/example.md"               \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]

  # Prints output:

  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/1                            ]]
  [[ "${output}" =~ 🔖                                                              ]]
  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md  ]]
  [[ "${output}" =~ renamed\ to                                                     ]]
  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/example.md                   ]]
}

@test "'rename folder/folder/<filename>' renames properly up one level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
  }

  run "${_NB}" rename                                       \
    "Example Folder/Sample Folder/Example File.bookmark.md" \
    "Example Folder/example.md"                             \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                              ]]

  # Prints output:

  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/1                            ]]
  [[ "${output}" =~ 🔖                                                              ]]
  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md  ]]
  [[ "${output}" =~ renamed\ to                                                     ]]
  [[ "${output}" =~ Example\\\ Folder/example.md                                    ]]
}

@test "'rename notebook:folder/<filename>' renames properly without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                  \
      --title   "Sample Title"                                  \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                 \
      --content "<https://2.example.test>"

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
    [[   -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                               ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                ]]
  }

  run "${_NB}" rename                               \
    "home:Example Folder/Example File.bookmark.md"  \
    "home:Example Folder/example.md"                \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                               ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/1                            ]]
  [[ "${output}" =~ 🔖                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Example\\\ File.bookmark.md  ]]
  [[ "${output}" =~ renamed\ to                                         ]]
  [[ "${output}" =~ Example\\\ Folder/example.md                        ]]
}

@test "'rename notebook:folder/folder/<filename>' renames properly on same level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]
  }

  run "${_NB}" rename                                             \
    "home:Example Folder/Sample Folder/Example File.bookmark.md"  \
    "home:Example Folder/Sample Folder/example.md"                \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
  [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ renamed\ to                                                         ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/example.md                  ]]
}

@test "'rename notebook:folder/folder/<filename>' renames properly up one level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]
  }

  run "${_NB}" rename                                             \
    "home:Example Folder/Sample Folder/Example File.bookmark.md"  \
    "home:Example Folder/example.md"                              \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                              ]]

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ renamed\ to                                                         ]]
  [[ "${output}" =~ home:Example\\\ Folder/example.md                                   ]]
}

# <id> ########################################################################

@test "'rename notebook:folder/folder/<id>' renames across notebooks and levels without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
    [[ ! -e "${NB_DIR}/one/example.md"                                              ]]
    [[ ! -e "${NB_DIR}/one/Example Folder/example.md"                               ]]
    [[ ! -e "${NB_DIR}/two/example.md"                                              ]]
    [[ ! -e "${NB_DIR}/two/Example Folder/example.md"                               ]]

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks add "two"

    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]
  }

  run "${_NB}" rename                     \
    "home:Example Folder/Sample Folder/1" \
    "two:Example Folder/example.md"       \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commits:

  cd "${NB_DIR}/home" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Delete:'

  cd "${NB_DIR}/two" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Add:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
  [[ ! -e "${NB_DIR}/one/example.md"                                              ]]
  [[ ! -e "${NB_DIR}/one/Example Folder/example.md"                               ]]
  [[ ! -e "${NB_DIR}/two/example.md"                                              ]]
  [[   -e "${NB_DIR}/two/Example Folder/example.md"                               ]]

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ moved\ to                                                           ]]
  [[ "${output}" =~ two:Example\\\ Folder/example.md                                    ]]
}

@test "'rename folder/<id>' renames properly without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                  \
      --title   "Sample Title"                                  \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                 \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
    [[   -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                               ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                ]]
  }

  run "${_NB}" rename           \
    "Example Folder/1"          \
    "Example Folder/example.md" \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                               ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ Example\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                            ]]
  [[ "${output}" =~ Example\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ renamed\ to                                   ]]
  [[ "${output}" =~ Example\\\ Folder/example.md                  ]]
}

@test "'rename folder/folder/<id>' renames properly on same level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]
  }

  run "${_NB}" rename                         \
    "Example Folder/Sample Folder/1"          \
    "Example Folder/Sample Folder/example.md" \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]

  # Prints output:

  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/1                            ]]
  [[ "${output}" =~ 🔖                                                              ]]
  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md  ]]
  [[ "${output}" =~ renamed\ to                                                     ]]
  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/example.md                   ]]
}

@test "'rename folder/folder/<id>' renames properly up one level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
  }

  run "${_NB}" rename                 \
    "Example Folder/Sample Folder/1"  \
    "Example Folder/example.md"       \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                              ]]

  # Prints output:

  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/1                            ]]
  [[ "${output}" =~ 🔖                                                              ]]
  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md  ]]
  [[ "${output}" =~ renamed\ to                                                     ]]
  [[ "${output}" =~ Example\\\ Folder/example.md                                    ]]
}

@test "'rename notebook:folder/<id>' renames properly without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                  \
      --title   "Sample Title"                                  \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                 \
      --content "<https://2.example.test>"

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
    [[   -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                               ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                ]]
  }

  run "${_NB}" rename                 \
    "home:Example Folder/1"           \
    "home:Example Folder/example.md"  \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                               ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/1                            ]]
  [[ "${output}" =~ 🔖                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Example\\\ File.bookmark.md  ]]
  [[ "${output}" =~ renamed\ to                                         ]]
  [[ "${output}" =~ Example\\\ Folder/example.md                        ]]
}

@test "'rename notebook:folder/folder/<id>' renames properly on same level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]
  }

  run "${_NB}" rename                               \
    "home:Example Folder/Sample Folder/1"           \
    "home:Example Folder/Sample Folder/example.md"  \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
  [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ renamed\ to                                                         ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/example.md                  ]]
}

@test "'rename notebook:folder/folder/<id>' renames properly up one level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]
  }

  run "${_NB}" rename                     \
    "home:Example Folder/Sample Folder/1" \
    "home:Example Folder/example.md"      \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                              ]]

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ renamed\ to                                                         ]]
  [[ "${output}" =~ home:Example\\\ Folder/example.md                                   ]]
}

# <title> #####################################################################

@test "'rename notebook:folder/folder/<title>' renames across notebooks and levels without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
    [[ ! -e "${NB_DIR}/one/example.md"                                              ]]
    [[ ! -e "${NB_DIR}/one/Example Folder/example.md"                               ]]
    [[ ! -e "${NB_DIR}/two/example.md"                                              ]]
    [[ ! -e "${NB_DIR}/two/Example Folder/example.md"                               ]]

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks add "two"

    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]
  }

  run "${_NB}" rename                                 \
    "home:Example Folder/Sample Folder/Example Title" \
    "two:Example Folder/example.md"                   \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commits:

  cd "${NB_DIR}/home" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Delete:'

  cd "${NB_DIR}/two" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Add:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
  [[ ! -e "${NB_DIR}/one/example.md"                                              ]]
  [[ ! -e "${NB_DIR}/one/Example Folder/example.md"                               ]]
  [[ ! -e "${NB_DIR}/two/example.md"                                              ]]
  [[   -e "${NB_DIR}/two/Example Folder/example.md"                               ]]

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ moved\ to                                                           ]]
  [[ "${output}" =~ two:Example\\\ Folder/example.md                                    ]]
}

@test "'rename folder/<title>' renames properly without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                  \
      --title   "Sample Title"                                  \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                 \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
    [[   -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                               ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                ]]
  }

  run "${_NB}" rename               \
    "Example Folder/Example Title"  \
    "Example Folder/example.md"     \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                               ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ Example\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                            ]]
  [[ "${output}" =~ Example\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ renamed\ to                                   ]]
  [[ "${output}" =~ Example\\\ Folder/example.md                  ]]
}

@test "'rename folder/folder/<title>' renames properly on same level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]
  }

  run "${_NB}" rename                             \
    "Example Folder/Sample Folder/Example Title"  \
    "Example Folder/Sample Folder/example.md"     \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]

  # Prints output:

  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/1                            ]]
  [[ "${output}" =~ 🔖                                                              ]]
  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md  ]]
  [[ "${output}" =~ renamed\ to                                                     ]]
  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/example.md                   ]]
}

@test "'rename folder/folder/<title>' renames properly up one level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
  }

  run "${_NB}" rename                             \
    "Example Folder/Sample Folder/Example Title"  \
    "Example Folder/example.md"                   \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                              ]]

  # Prints output:

  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/1                            ]]
  [[ "${output}" =~ 🔖                                                              ]]
  [[ "${output}" =~ Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md  ]]
  [[ "${output}" =~ renamed\ to                                                     ]]
  [[ "${output}" =~ Example\\\ Folder/example.md                                    ]]
}

@test "'rename notebook:folder/<title>' renames properly without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                  \
      --title   "Sample Title"                                  \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                 \
      --content "<https://2.example.test>"

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
    [[   -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                               ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                ]]
  }

  run "${_NB}" rename                   \
    "home:Example Folder/Example Title" \
    "home:Example Folder/example.md"    \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                  ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                               ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/1                            ]]
  [[ "${output}" =~ 🔖                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Example\\\ File.bookmark.md  ]]
  [[ "${output}" =~ renamed\ to                                         ]]
  [[ "${output}" =~ Example\\\ Folder/example.md                        ]]
}

@test "'rename notebook:folder/folder/<title>' renames properly on same level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]
  }

  run "${_NB}" rename                                 \
    "home:Example Folder/Sample Folder/Example Title" \
    "home:Example Folder/Sample Folder/example.md"    \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]
  [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/example.md"                ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ renamed\ to                                                         ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/example.md                  ]]
}

@test "'rename notebook:folder/folder/<title>' renames properly up one level without errors." {
  {
    run "${_NB}" init
    run "${_NB}" add "Sample File.bookmark.md"                                \
      --title   "Sample Title"                                                \
      --content "<https://1.example.test>"

    run "${_NB}" add "Example Folder/Sample Folder/Example File.bookmark.md"  \
      --title   "Example Title"                                               \
      --content "<https://2.example.test>"

    [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
    [[   -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
    [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
    [[ ! -e "${NB_DIR}/home/Example Folder/example.md"                              ]]

    run "${_NB}" notebooks add "one"
    run "${_NB}" notebooks use "one"

    [[ "$("${_NB}" notebooks current)" == "one" ]]
  }

  run "${_NB}" rename                                 \
    "home:Example Folder/Sample Folder/Example Title" \
    "home:Example Folder/example.md"                  \
    --force

  printf "\${status}: '%s'\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  # Returns status 0:

  [[ ${status} -eq 0 ]]

  # Creates git commit:

  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Rename:'

  # Renames file:

  [[   -e "${NB_DIR}/home/Sample File.bookmark.md"                                ]]
  [[ ! -e "${NB_DIR}/home/Example Folder/Sample Folder/Example File.bookmark.md"  ]]
  [[ ! -e "${NB_DIR}/home/example.md"                                             ]]
  [[   -e "${NB_DIR}/home/Example Folder/example.md"                              ]]

  # Prints output:

  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/1                           ]]
  [[ "${output}" =~ 🔖                                                                  ]]
  [[ "${output}" =~ home:Example\\\ Folder/Sample\\\ Folder/Example\\\ File.bookmark.md ]]
  [[ "${output}" =~ renamed\ to                                                         ]]
  [[ "${output}" =~ home:Example\\\ Folder/example.md                                   ]]
}
