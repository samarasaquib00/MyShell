/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 * DO NOT PUT THIS PROJECT IN A PUBLIC REPOSITORY LIKE GIT. IF YOU WANT
 * TO MAKE IT PUBLICALLY AVAILABLE YOU NEED TO REMOVE ANY SKELETON CODE
 * AND REWRITE YOUR PROJECT SO IT IMPLEMENTS FUNCTIONALITY DIFFERENT THAN
 * WHAT IS SPECIFIED IN THE HANDOUT. WE OFTEN REUSE PART OF THE PROJECTS FROM
 * SEMESTER TO SEMESTER AND PUTTING YOUR CODE IN A PUBLIC REPOSITORY
 * MAY FACILITATE ACADEMIC DISHONESTY.
 */

#include <cstdio>

#include "shell.hh"
#include <unistd.h>
//#include "shell.l"

#include <sys/wait.h>


int yyparse(void);

void Shell::prompt() {
  if ( isatty(0) ) {
    if (getenv("PROMPT")) {
      printf(getenv("PROMPT"));
    } else {
      printf("myshell>");
    }
  }

  fflush(stdout);
}

/* SIGINT */

/* CTRL+C Sig */

extern "C" void ctrlC_sig( int sig ) {
  if (sig == SIGINT) {
    Shell::_currentCommand.clear();
    printf("\n");
    /* Print shell prompt again? */
    if (isatty (0)) {
    Shell::prompt();
    }
  }
}


/* Zombie Sig */
extern "C" void zombie( int sig ) {
    if (sig == SIGCHLD) {
    while(waitpid(-1, NULL, WNOHANG) > 0);
    }
}

int main(int argc, char **argv) {

  // initialize path
  Shell::_path = argv[0];

  /* Handle CTRL+C Sig */
  struct sigaction sa;
  sa.sa_handler = ctrlC_sig;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART;

  if(sigaction(SIGINT, &sa, NULL)){
      perror("sigaction");
      exit(-1);
  }



  /* Handle Zombie Processes */
  struct sigaction z;
  z.sa_handler = zombie;
  sigemptyset(&z.sa_mask);
  z.sa_flags = SA_RESTART;

  if (sigaction(SIGCHLD, &z, NULL)){
      perror("sigaction");
      exit(-1);
  }
  //Shell::_isSrc = false;
  Shell::prompt();
  yyparse();
}

Command Shell::_currentCommand;
int Shell::_returnCode;
int Shell::_lastPid;
char* Shell::_path;
std::string Shell::_lastArg;
