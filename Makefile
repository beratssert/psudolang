TARGET = psudo
CC = gcc
LEX = flex
YACC = bison

LEX_FILE = psudo.l
YACC_FILE = psudo.y

LEX_C = lex.yy.c
YACC_C = psudo.tab.c
YACC_H = psudo.tab.h

all: $(TARGET)

$(TARGET): $(LEX_C) $(YACC_C)
	$(CC) $(YACC_C) $(LEX_C) -o $(TARGET)

$(YACC_C) $(YACC_H): $(YACC_FILE)
	$(YACC) -d $(YACC_FILE)

$(LEX_C): $(LEX_FILE) $(YACC_H)
	$(LEX) $(LEX_FILE)

clean:
	rm -f $(TARGET) $(LEX_C) $(YACC_C) $(YACC_H)