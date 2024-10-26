#!/bin/bash

NUMBER="$(( $RANDOM%1000 ))"
NUMBER_OF_GUESSES=0
PSQL="psql -U <user> -d number_guess -t --no-align -c"
USER_ID=

function ADD_USER () {
  local USERNAME=$1
  local INSERT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  local ID=$($PSQL "SELECT id FROM users WHERE username='$USERNAME'")

  USER_ID=$ID
}

function CHECK_GUESS () {
  GUESS=$1

  (( NUMBER_OF_GUESSES++ ))

  if (( $GUESS == $NUMBER ))
  then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $NUMBER. Nice job!"
    SAVE_GAME
  elif (( $GUESS < $NUMBER ))
  then
    echo "It's higher than that, guess again:"
    INIT_GAME 1
  elif (( $GUESS > $NUMBER ))
  then
    echo "It's lower than that, guess again:"
    INIT_GAME 1
  fi
}

function GET_USER_ID_BY_USERNAME () {
  local USERNAME=$1
  local QUERY=$($PSQL "SELECT id FROM users WHERE username='$USERNAME'")

  USER_ID=$QUERY
}

function GET_USER_GAME_HISTORY () {
  local USERNAME=$1

  GET_USER_ID_BY_USERNAME $USERNAME
  
  # Don't query for game history if the user doesn't exist
  if [[ -z $USER_ID ]]
  then
    ADD_USER $USERNAME
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  else
    local NUMBER_OF_GAMES=$($PSQL "SELECT COUNT(number) FROM games WHERE user_id=$USER_ID LIMIT 1")
    local NUMBER_OF_GAMES=${NUMBER_OF_GAMES:=0} # Default to 0; User may have been created but not played a game
    local BEST_GAME=$($PSQL "SELECT MIN(guesses) FROM users LEFT JOIN games ON users.id = games.user_id WHERE id=$USER_ID")
    local BEST_GAME=${BEST_GAME:=0} # Default to 0; User may have been created but not played a game
    echo "Welcome back, $USERNAME! You have played $NUMBER_OF_GAMES games, and your best game took $BEST_GAME guesses."
  fi
}

function INIT () {
  echo "Enter your username:"
  read USERNAME

  echo ${#USERNAME}

  if (( ${#USERNAME} > 22 ))
  then
    echo "Usernames cannot be longer than 22 characters."
    INIT
  elif [[ -z $USERNAME ]]
  then
    echo "Usernames cannot be empty."
    INIT
  else
    GET_USER_GAME_HISTORY $USERNAME
  fi

}

function INIT_GAME () {
  SHOULD_ECHO=${1:-0}
  
  if [[ $SHOULD_ECHO == 0 ]]
  then
    echo "Guess the secret number between 1 and 1000:"
  fi

  read INPUT

  if [[ -z $INPUT ]] || [[ ! "${INPUT}" =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    INIT_GAME 1
  else
    CHECK_GUESS $INPUT
  fi
}

function SAVE_GAME () {
  local QUERY=$($PSQL "INSERT INTO games(number, guesses, user_id) VALUES ($NUMBER, $NUMBER_OF_GUESSES, $USER_ID)")
}


INIT
INIT_GAME
