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

/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{
#include <string>
#include "shell.hh"
#include <cstring>

#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <cpp_string> WORD
%token NOTOKEN NEWLINE GREAT LESS GREATAMPERSAND GREATGREATAMPERSAND TWOGREAT AMPERSAND GREATGREAT PIPE

%{
//#define yylex yylex
#include <cstdio>
#include "shell.hh"
#include <cstring>
#include <regex.h>
#include <dirent.h>
#include <sys/types.h>

void yyerror(const char * s);
int yylex();
void expandWildcardsIfNecessary(char * arg);
void expandWildcard(char * prefix, char * suffix);


%}

%%

goal:
  commands
  ;

commands:
  command
  | commands command
  ;

command: simple_command
;

  simple_command:
  pipe_list iomodifier_opt_list background_opt NEWLINE {
    //printf("   Yacc: Execute command\n");
    Shell::_currentCommand.execute();
  }
  | NEWLINE 
  | error NEWLINE { yyerrok; }
  ;

command_and_args:
  command_word argument_list {
    Shell::_currentCommand.
    // Shell::_currentCommand.execute();
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

  pipe_list:
  pipe_list PIPE command_and_args
  | command_and_args
  ;


argument_list:
  argument_list argument
  | /* can be empty */
  ;


// AFTER
/*argument:
  WORD {
    expandWildcardsIfNecessary($1);
  };
*/

// BEFORE
argument:
  WORD {
    //printf("   Yacc: insert argument \"%s\"\n", $1->c_str());
    Command::_currentSimpleCommand->insertArgument( $1 );\
  }
  ;



command_word:
  WORD {
    //printf("   Yacc: insert command \"%s\"\n", $1->c_str());
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;


iomodifier_opt_list:
  iomodifier_opt_list iomodifier_opt
  |
;

iomodifier_opt:
  GREAT WORD {
    // outfile
    //printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._countOutput += 1;
    

  }
  | LESS WORD {
    // infile
    // printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._inFile = $2;

  }
  | GREATAMPERSAND WORD {
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._countOutput += 1;
    Shell::_currentCommand._errFile = $2;

  }
  | GREATGREATAMPERSAND WORD {
    // printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._countOutput += 1;
    Shell::_currentCommand._errFile = $2;
    Shell::_currentCommand._append = true;


  }
  | TWOGREAT WORD {
    // printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._errFile = $2;
  }
  | GREATGREAT WORD {
    // printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._countOutput += 1;
    Shell::_currentCommand._append = true;
  }
  ;
  // Note that file descriptors 0, 1, and 2 correspond to input, output, and error respectively.

  background_opt:
  AMPERSAND {
    Shell::_currentCommand._background = true;
  }
  | /* can be empty */
  ;

%%

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}




//void expandWildcardsIfNecessary(char * arg) {
/*void expandWildcardsIfNecessary(char *arg) {
  //char *arg = strdup(garg);
  // Return if arg does not contain ‘*’ or ‘?’
  if ((strchr(arg, '*') == NULL) && (strchr(arg, '?') == NULL)) {
    Command::_currentSimpleCommand->insertArgument(arg);
    return;
  }


  // 1. Convert wildcard to regular expression
  // Convert “*” -> “.*”
  // “?” -> “.”
  // “.” -> “\.” and others you need
  // Also add ^ at the beginning and $ at the end to match
  // the beginn the end of the word.
  // Allocate enough space ing ant for regular expression
  char * reg = (char*)malloc(2*strlen(arg)+10);
  char * a = arg;
  char * r = reg;
  *r = '^'; r++;  // match beginning of line
  while (*a) {
    if (*a == '*') { *r='.'; r++; *r='*'; r++; }
    else if (*a == '?') { *r = '.'; r++;}
    else if (*a == '.') { *r = '\\'; r++; *r='.'; r++;}
    else { *r=*a; r++;}
    a++;
  }
  *r='$'; r++; *r=0;


  // 2. compile regular expression. See lab3-src/regular.cc
  regex_t r1;
  int expbuf = regcomp(&r1, reg, REG_EXTENDED|REG_NOSUB);
  if (expbuf != 0) {
    perror("compile");
    return;
  }

  // 3. List directory and add as arguments the entries
  // that match the regular expression
  DIR *dir = opendir(".");
  if (dir == NULL) {
    perror("opendir");
    return;
  }

  struct dirent * ent;
  while ( (ent = readdir(dir)) != NULL) {
    // check if name matches
    if (regexec(ent->d_name, expbuf ) == 0) {
      // add argument
      Command::_currentSimpleCommand->
      insertArgument(strdup(ent->d_name));
    }
  }

  closedir(dir);
}*/





#if 0
main()
{
  yyparse();
}
#endif
