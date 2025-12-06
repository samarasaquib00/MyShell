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
#include <cstdlib>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <unistd.h>

#define _GNU_SOURCE             /* See feature_test_macros(7) */
#include <fcntl.h>              /* Definition of O_* constants */
#include <unistd.h>

#include <cstring>              /* For strcmp */


#include <iostream>

#include "command.hh"
#include "shell.hh"

Command::Command()
{
    // Initialize a new vector of Simple Commands
    _simpleCommands = std::vector<SimpleCommand *>();

    _outFile = NULL;
    _inFile = NULL;
    _errFile = NULL;
    _background = false;
    _append = false;
    _countOutput = 0;
}

void Command::insertSimpleCommand(SimpleCommand *simpleCommand)
{
    // add the simple command to the vector
    _simpleCommands.push_back(simpleCommand);
}

void Command::clear()
{
    // deallocate all the simple commands in the command vector
    for (auto simpleCommand : _simpleCommands)
    {
        delete simpleCommand;
    }

    // remove all references to the simple commands we've deallocated
    // (basically just sets the size to 0)
    _simpleCommands.clear();


    if (_outFile && !_errFile)
    {
        delete _outFile;
    }
    _outFile = NULL;

    if (_inFile)
    {
        delete _inFile;
    }
    _inFile = NULL;

    if (_errFile && !_outFile && _errFile != NULL)
    {
        delete _errFile;
    }
    _errFile = NULL;

    _background = false;

    _countOutput = 0;
}

void Command::print()
{

    printf("\n\n");
    printf("              COMMAND TABLE                \n");
    printf("\n");
    printf("  #   Simple Commands\n");
    printf("  --- ----------------------------------------------------------\n");

    int i = 0;
    // iterate over the simple commands and print them nicely
    for (auto &simpleCommand : _simpleCommands)
    {
        printf("  %-3d ", i++);
        simpleCommand->print();
    }

    printf("\n\n");
    printf("  Output       Input        Error        Background\n");
    printf("  ------------ ------------ ------------ ------------\n");
    printf("  %-12s %-12s %-12s %-12s\n",
           _outFile ? _outFile->c_str() : "default",
           _inFile ? _inFile->c_str() : "default",
           _errFile ? _errFile->c_str() : "default",
           _background ? "YES" : "NO");
    printf("\n\n");
}

void Command::execute()
{
    // Don't do anything if there are no simple commands
    if (_simpleCommands.size() == 0)
    {
        Shell::prompt();

        return;
    }



    // IF COMMAND = "EXIT", Call exit(1)
    if (strcmp(_simpleCommands[0]->_arguments[0]->c_str(),"exit") == 0) {
      printf("Exiting Shell\n");
      exit(1);
    }


    // Check for AMBIGUOUS output
    if (_countOutput > 1 && _append == false) {
      printf("Ambiguous output redirect.\n");
      exit(1);
    }


    // Print contents of Command data structure
    //print();

    int tmpin = dup(0);     //input
    int tmpout = dup(1);    //output
    int tmperr = dup(2);   //error

    //set the initial output
    int fdin;
    if (_inFile) {
        fdin = open(_inFile->c_str(), O_RDONLY, 0664);
    } else {
        fdin = dup(tmpin);
    }

    //2
    // create new process
    int ret = 0;
    int fdout;
    int fderr;
    if (_errFile) {
      if (_append) {
        fderr=open(_outFile->c_str(), O_WRONLY | O_APPEND, 0664);
      } else {
        fderr = open(_errFile->c_str(), O_CREAT|O_WRONLY|O_TRUNC,0664);
      }
    }
    else {    //28
      fderr = dup(tmperr);
    }
    dup2(fderr, 2);
    close(fderr);


    for (int i = 0; i < _simpleCommands.size(); i++) {

        // FILE REDIRECTION
        dup2(fdin, 0);
        close(fdin);

        // BUILT-IN FUNCTIONS

        // SETENV
        if (strcmp(_simpleCommands[i]->_arguments[0]->c_str(),"setenv") == 0) {
          const char *A = _simpleCommands[i]->_arguments[1]->c_str();
          const char *B = _simpleCommands[i]->_arguments[2]->c_str();
          if(setenv(A, B, 1)) {
            perror("setenv");
          }

          clear();
          Shell::prompt();
          //Shell::_lastPid = ret;
          return;
        }

        // UNSETENV
        if (strcmp(_simpleCommands[i]->_arguments[0]->c_str(),"unsetenv") == 0) {
          //clear();
          if (unsetenv(_simpleCommands[i]->_arguments[1]->c_str())) {
            perror("unsetenv");
          }
          clear();
          Shell::prompt();
          //exit(1);
          //Shell::_returnCode = WEXITSTATUS(ret);
          return;
        }


        // CD
        if (strcmp(_simpleCommands[i]->_arguments[0]->c_str(),"cd") == 0) {

          // If there is no second argument, default to Home directory
          if (_simpleCommands[i]->_arguments.size() < 2) {
            chdir(getenv("HOME"));
          } else {
            const char *path = _simpleCommands[i]->_arguments[1]->c_str();
            if (chdir(path) != 0)  {                          // if path is not found
              fprintf(stderr, "cd: can't cd to notfound");    // print to stderr
            };
          }
          clear();
          Shell::prompt();
          //exit(1);
          //_returnCode = 1;
          //Shell::_returnCode = WEXITSTATUS(ret);
          close(tmpin);
          close(tmpout);
          close(tmperr);
          return;
        }

        if (i == _simpleCommands.size() - 1) {
            // Fix File Redirection
            if (_outFile) {
              if (_append) {
                fdout=open(_outFile->c_str(), O_WRONLY | O_APPEND, 0664);
              }
              else {
                fdout = open(_outFile->c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0664);
              }
            } else {
              fdout = dup(tmpout);

            }


        } else {        //34
            //not last, create PIPE
            int fdpipe[2];
            pipe(fdpipe);
            fdout=fdpipe[1];
            fdin=fdpipe[0];

        }


        //redirect output, 44
        dup2(fdout, 1);
        close(fdout);

        // should I move this?

        //close(fdin);


        // create child process, 48
        // FORK
        ret = fork();

        // if ret = 0
        if (ret == 0) {
            // child
            // call execvp

            // move out of if?
            int sCom_size = _simpleCommands[i]->_arguments.size();
            char ** argv = new char*[sCom_size+1];
            for (int j = 0; j < sCom_size; j++) {
                argv[j] = (char *)_simpleCommands[i]->_arguments[j]->c_str();
            }

            argv[sCom_size] = NULL;

            // move out of if?


            // SETENV
            close(fdin);
            close(tmpin);
            close(tmpout);
            close(tmperr);




            // PRINTENV
            /* The variable environ points to an array of pointers to strings called the "environment" */
            if (strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "printenv") == 0) {
              char ** env = environ;

              /* Iterate through the strings in array env */
              int index = 0;
              while (env[index] != NULL) {
                printf("%s\n", env[index]);
                index++;
              }
              exit(1);
            }

            //fprintf(stderr, "%s\n", _simpleCommands[i]->_arguments[0]->c_str());
            execvp(_simpleCommands[i]->_arguments[0]->c_str(), argv);
            perror("execvp");
            _exit(1);
        }


        // else if <0, error
        else if (ret < 0) {
            //exit
            perror("fork");
            //Shell::_returnCode = WEXITSTATUS(ret);
            return;
        }
        //close(fdin);

      } //end for

      Shell::_lastArg = *(_simpleCommands[_simpleCommands.size()-1]->_arguments[_simpleCommands[_simpleCommands.size() - 1]->_arguments.size() - 1]);

        // restore in/out defaults, 57
        dup2(tmpin, 0);
        dup2(tmpout, 1);
        dup2(tmperr, 2);
        close(tmpin);
        close(tmpout);
        close(tmperr);
        //close(fdin);
        //close(fdout);
        //close(fderr);

        //parent
        // if !background

        if (!_background) {
            int status;
            waitpid(ret,&status, 0);
            Shell::_returnCode = WEXITSTATUS(status);
            if (Shell::_returnCode != 0) {
              if (getenv("ON_ERROR")) {
                printf(getenv("ON_ERROR"));
                printf("\n");
              }
            }
        } else {
          Shell::_lastPid = ret;
        }
    clear();

    // Print new prompt
    Shell::prompt();
}

SimpleCommand *Command::_currentSimpleCommand;
