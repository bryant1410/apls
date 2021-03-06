%-*-Prolog-*-  
% setup indented on 3/22/2002 by 'JOLI' 1.0.

/**************************************************************************\
* Author:	Ray Reeves                                                     *
* Created:	January 1992                                                   *
*
\**************************************************************************/
setCapStream(C) :-
  cntr_set(1, C).

getCapStream(C) :-
  cntr_get(1, C).

setCol(Col) :-
  cntr_set(2, Col).

incCol(Col) :-
  cntr_inc(2, Col).

decCol(Col) :-
  cntr_dec(2, Col).

getCol(Col) :-
  cntr_get(2, Col).

resetCol :-
  cntr_set(2, 0).

incLines :-
  cntr_inc(3, _).

decLines :-
  cntr_dec(3, _).

getLines(Lines) :-
  cntr_get(3, Lines).

setLines(Lines) :-
  cntr_set(3, Lines).

incBarLines :-
  cntr_inc(4, _).

setBarLines(BarLines) :-
  cntr_set(4, BarLines).

getBarLines(BarLines) :-
  cntr_get(4, BarLines).

getCols(Cols) :-
  cntr_get(5, Cols).

setCols(Cols) :-
  cntr_set(5, Cols).

decCols :-
  cntr_dec(5, _).

setup(Puzzle, Domain) :-
  assert(varList([])),
  reset,
  atomlist_concat([Puzzle, '.', cry], Cryptogram),
  open(Cryptogram, read, CryStream1, [type(binary)]),
  get0(CryStream1, A),
  getDims(A, CryStream1),                     % get puzzle dimensions
  setCol(1),
  decCols,
  getCols(Cols),
  decLines,
  getBarLines(BarLines),
  close(CryStream1),                          % to shake off eof
  abolish(Puzzle/0),
  atomlist_concat([Puzzle, '.', pro], Cap),
  open(Cap, write, CapStream), !,             % open cap file for write
  setCapStream(CapStream),                    % the cap code stream
  date(Month, Day, Year),
  write(CapStream, `%% Code generated by crypto on `), 
  write(CapStream, Month), write(CapStream, '/'), write(CapStream, Day), 
  write(CapStream, '/'), write(CapStream, Year), write(CapStream, `.\n\n`), 
  write(CapStream, `:- dcg_terminal(draw).\n`), 
  write(CapStream, `:- noNonTerminals.\n\n`), write(CapStream, Puzzle), 
  write(CapStream, ` :-\n    solution(`), write(CapStream, Puzzle), 
  write(CapStream, ','), write(CapStream, Domain), 
  write(CapStream, `, X).\n\n`), write(CapStream, `solution(`), 
  write(CapStream, Puzzle), write(CapStream, `) -->`), 
  open(Cryptogram, read, CryStream2, [type(binary)]), % reopen cryptogram
  getChar(CryStream2, FirstChar, Col),        % get initial char and col
  doChar(FirstChar, Col, 1, CryStream2, first), % assert pos & first chars
  close(CryStream2),
  (
     isProd(Kind) ->
     (
        Kind = implicit ->
        first(_, FirstCol2, 2),
        Bar2Lino is Cols - FirstCol2 + 5,     % virtual bar 2 line number
        assert(barLine(2, Bar2Lino, virtual)),
        ProdLine is Bar2Lino + 1,
        setLines(ProdLine),
        moveProdLine(ProdLine) ;

        true
     ),
     getLines(Lines),
     doProd(Cols, [], VarList),               % prod puzzle
     write(CapStream, `\n   displayGram(`), write(CapStream, Cols), 
     write(CapStream, `, `), write(CapStream, Lines), 
     write(CapStream, `, \n               [`), 
     writeListNames(CapStream, VarList),
     write(CapStream, `], \n               `), write(CapStream, VarList), 
     write(CapStream, `\t).\n\n`) ;

     doSum(CapStream)                         % sum puzzle
  ),
  (                                           % compile all positions
     pos(A1, A2, A3, A4),
     write(CapStream, `pos('`), write(CapStream, A1), 
     write(CapStream, `', `), write(CapStream, A2), write(CapStream, `, `), 
     write(CapStream, A3), write(CapStream, `, `), write(CapStream, A4), 
     write(CapStream, `).\n`), 
     fail ;

     true
  ),
  (                                           % compile all bar lines
     barLine(B1, B2, B3),
     write(CapStream, `barLine(`), write(CapStream, B1), 
     write(CapStream, `, `), write(CapStream, B2), write(CapStream, `, `), 
     write(CapStream, B3), write(CapStream, `).\n`), 
     fail ;

     true
  ),
  abolish(pos/4),
  abolish(barLine/3),
  close(CapStream).

moveProdLine(ProdLino) :-
  retract(pos(Name, Col, 4, Wild)),
  assert(pos(Name, Col, ProdLino, Wild)), !,
  moveProdLine(ProdLino).
moveProdLine(_).

reset :-
  cntr_set(2, 1),                             % col
  cntr_set(3, 1),                             % lines
  cntr_set(4, 0),                             % bar lines
  cntr_set(5, 0),                             % cols
  abolish(varList/1),
  abolish(solution/3),
  abolish(pos/4),
  abolish(barLine/3),
  abolish(first/3).

isProd(explicit) :-
  getBarLines(2).                             % explicit pps
isProd(implicit) :-                           % implicit
  getBarLines(1),                             % only one bar line
  first(_, FirstCol1, 1),
  first(_, FirstCol2, 2),
  first(_, FirstCol4, 4),
  (
     FirstCol1 < FirstCol2 ->                 % carry is more than one digit
     FirstCol4 < (FirstCol1 - 1) ;

     FirstCol4 < (FirstCol2 - 1)
  ).

getDims('end_of_file', Stream).               % EOF
getDims(0'-, Stream) :-                       % bar
  incBarLines,
  getBarLines(BarLine),
  getLines(Lino),
  assert(barLine(BarLine, Lino, real)),
  repeat,
  get0(Stream, A),                            % get the whole bar
  A =\= 0'-, !,
  getDims(A, Stream).
getDims(13, Stream) :-                        % CR
  get0(Stream, A), !,
  getDims(A, Stream).
getDims(10, Stream) :-                        % LF
  getCol(Col),
  getCols(Cols),
  (Col > Cols -> setCols(Col) ;  true),
  resetCol,
  incLines,
  get0(Stream, A), !,
  (A = 10 ;  getDims(A, Stream)).             % blank line stops it
getDims(_, Stream) :-                         % other
  incCol(_),
  get0(Stream, A), !,
  getDims(A, Stream).

check(X, X, X).

getChar(Stream, Ascii, Col) :-
  get0(Stream, Ascii),
  incCol(Col).

/* 
 arg1 is the char to be processed, then it gets another and recurses.
 asserts pos and first
 */

doChar(end_of_file, _, _, Stream, _) :- !.
doChar(0'-, Col, Lino, Stream, _) :-          % - bar line, skip it
  repeat,
  getChar(Stream, Ascii, _),
  not Ascii == 0'-,                           % repeat escape
  doChar(Ascii, Col, Lino, Stream, notfirst).
doChar(0'*, StarCol, Lino, Stream, First) :- !, % * wild card on domain
  Cursor is 10*Lino + StarCol,
  atomlist_concat(['R', Cursor], Var),
  assert(pos(Var, StarCol, Lino, 0)),
  noteFirst(First, Var, StarCol, Lino),
  getChar(Stream, A, Col),                    % gets A and it's Col
  doChar(A, Col, Lino, Stream, notfirst).
doChar(0'., DotCol, Lino, Stream, First) :- !, % . wild card on 0 - 9
  Cursor is 10*Lino + DotCol,
  atomlist_concat(['R', Cursor], Var),
  assert(pos(Var, DotCol, Lino, 1)),          % set Wild flag
  noteFirst(First, Var, DotCol, Lino),
  getChar(Stream, A, Col),
  doChar(A, Col, Lino, Stream, notfirst).
doChar(10, _, Lino, Stream, _) :-             % new line
  setCol(1),
  getChar(Stream, A, Col), !,
  Lino1 is Lino + 1,
  doChar(A, Col, Lino1, Stream, first).
doChar(13, _, Lino, Stream, First) :-         % cr
  getChar(Stream, A, Col), !,
  doChar(A, Col, Lino, Stream, First).
doChar(32, _, Lino, Stream, First) :-         % space
  getChar(Stream, A, Col), !,
  doChar(A, Col, Lino, Stream, First).
doChar(Ascii, FirstCol, Lino, Stream, First) :- % general case
  name(Var, [Ascii]),
  assert(pos(Var, FirstCol, Lino, 0)),
  noteFirst(First, Var, FirstCol, Lino),
  getChar(Stream, A, Col),
  doChar(A, Col, Lino, Stream, notfirst).

noteFirst(first, FirstVar, FirstCol, Lino) :- % first char in the line
  assert(first(FirstVar, FirstCol, Lino)).
noteFirst(_, _, _, _).

doSum(Stream) :-                              % generates the cap code 
  getCols(Cols),
  getLines(Lines),
  first(X, _, Lines),
  write(Stream, `   [`), write(Stream, X), write(Stream, `], `), 
  write(Stream, X), write(Stream, ` > 0, `), write(Stream, X), 
  write(Stream, ` < `), write(Stream, Lines), write(Stream, `,`), 
  ToLine is Lines - 2,
  sumCols(Cols, 1, ToLine, [X], VarList),
  write(Stream, `\n   displayGram(`), write(Stream, Cols), 
  write(Stream, `, `), write(Stream, Lines), 
  write(Stream, `, \n               [`), 
  writeListNames(Stream, VarList),
  write(Stream, `], \n                      `), write(Stream, VarList), 
  write(Stream, `\t).\n\n`).

sumCols(Col, FromLine, ToLine) -->            % recurse over Col
  {
     getCapStream(Stream),
     getCols(Cols),
     Col > 0, !,
     CarryIx is Col - 1,                      % the carry index
     getLines(Lines),
     pos(SumSymbol, Col, Lines, Wild)         % get SumSymbol
  },
  getVars(Col, ToLine),                       % get Vars in this col
  {
     (
        Col = Cols ->                         % first col
        write(Stream, `\n   evaluate(0 `) ;

        write(Stream, `\n   evaluate(SCarry`), write(Stream, Col), 
        write(Stream, ` `)
     ),
     barLine(1, BarLine, _),
     Rows is BarLine - 1,
     sumCol(Col, 1, Rows),                    % for each row in this col
     (
        Col = 1 ->
        write(Stream, `, 0, `), write(Stream, SumSymbol), 
        write(Stream, `), `), 
        (
           first(SumSymbol, _, ToLine) ->
           write(Stream, `   `), write(Stream, SumSymbol), 
           write(Stream, ` > 0, `) ;

           true
        ) ;

        write(Stream, `, SCarry`), write(Stream, CarryIx), 
        write(Stream, `, `), write(Stream, SumSymbol), write(Stream, `), `)
     )
  },
  validateVar(SumSymbol, Wild),
  {Col1 is Col - 1},
  ({Col1 > 0} -> sumCols(Col1, FromLine, ToLine) ;  []).

sumCol(Col, FromLine, ToLine) :-              % recurse over FromLine
  getCapStream(Stream),
  FromLine =< ToLine, !,
  (
     pos(Var, Col, FromLine, _) ->            % if there is a char
     write(Stream, `+ `), write(Stream, Var), write(Stream, ` `) ;

     true                                     % else skip it
  ),
  From is FromLine + 1,
  sumCol(Col, From, ToLine).
sumCol(_, _, _).

validateVar(Char, Wild) -->
  (
     check(VarList),                          % get the var list
     {member(Char, VarList)} ;                % is member, do nothing

     - [Char],                                % cons Char onto VarList 
     {
        getCapStream(Stream),                 % get stream 
        (                                     % code to draw new char
           Wild = 1 ->                        % wild
           write(Stream, `\n   *[`), write(Stream, Char), 
           write(Stream, `], `) ;

           write(Stream, `\n   [`), write(Stream, Char), 
           write(Stream, `], `)
        ),
        (                                     % not wild
           first(Char, _, _) ->               % first digit must be > 0
           write(Stream, Char), write(Stream, ` > 0, `) ;

           true
        )
     }
  ).

/* 
 puts out capcode for single digit products. not recursive 
 arg 1 is 'first'/'last' flag for PPLino
 arg 2 is multiplicand
 arg 3 is multiplier
 */
prodEval(Flag, F1, F2, PPCol, PPLino, PPName) :- 
% flow(prodEval(Flag,F1, F2, PPCol,PPLino)),
	(                                          % set CarryOut string
		 isFirstF1(Flag) ->                                
		 (                                      % F1 is first on line 1
			  first(_, PPCol, PPLino) ->         % if first(, Col, Lino)
			  MSCarry = no,                    % there is no ms pp carry
			  CarryOut = 0 ;
			  
			  MSCarry = yes,                    % ms pp has a carry
           first(CarryOut, _, PPLino)        % CarryOut is it's name
		 ) ;

		 MSCarry = no,                         % F1 is not the 1st on line 1
		 atomlist_concat(['ProdCarry', PPLino, PPCol], CarryOut)
	), 
	(                                         % set CarryIn string
		 isLastF1(Flag) ->
		 CarryIn = 0 ;

		 PPCol1 is PPCol + 1,
		 atomlist_concat(['ProdCarry', PPLino, PPCol1], CarryIn)

	),
	getCapStream(Stream),         
	write(Stream, `\n   evaluate(`), write(Stream, F1), write(Stream, ` * `),
	write(Stream, F2), write(Stream, ` + `), write(Stream, CarryIn),
	write(Stream, `, `), write(Stream, CarryOut),  write(Stream, `, `),
	write(Stream, PPName),  write(Stream, `), `),
  (
		MSCarry == yes->                         % if there is a carry out
%		write(Stream, `\n   [`), write(Stream, CarryOut), write(Stream, `],  `),
		write(Stream, CarryOut), write(Stream, ` > 0, `) ;

		true
  ).
	  
isFirstF1(Flag) :-
	1 is Flag /\ 1.

isLastF1(Flag) :-
	2 is Flag /\ 2.

/*
prodEval(isLastF1, F1, F2, PPCol, PPLino, PPName) :- !,
  getCapStream(Stream),                       % no carry in
  write(Stream, `\n   evaluate(`), write(Stream, F1), write(Stream, ` * `), 
  write(Stream, F2), write(Stream, `, ProdCarry`), write(Stream, PPLino), 
  write(Stream, PPCol), write(Stream, `, `), write(Stream, PPName), 
  write(Stream, `), `).
prodEval(isFirstF1, F1, F2, PPCol, PPLino, PPName) :- !,
  getCapStream(Stream),
  CarryIn is PPCol + 1,
  CarryCol is PPCol - 1,
  (
     first(CarrySymbol, CarryCol, PPLino) ->
     write(Stream, `\n   evaluate(`), write(Stream, F1), 
     write(Stream, ` * `), write(Stream, F2), write(Stream, ` + ProdCarry`), 
     write(Stream, PPLino), write(Stream, CarryIn), write(Stream, `, `), 
     write(Stream, CarrySymbol), write(Stream, `, `), write(Stream, PPName), 
     write(Stream, `), `), write(Stream, `\n   [`), 
     write(Stream, CarrySymbol), write(Stream, `],  `), 
     write(Stream, CarrySymbol), write(Stream, ` > 0, `) ;

     write(Stream, `\n   evaluate(`), write(Stream, F1), 
     write(Stream, ` * `), write(Stream, F2), write(Stream, ` + ProdCarry`), 
     write(Stream, PPLino), write(Stream, CarryIn), write(Stream, `, 0, `), 
     write(Stream, PPName), write(Stream, `), `)
  ).
prodEval(0, F1, F2, PPCol, PPLino, PPName) :- % regular
  CarryIn is PPCol + 1,
  getCapStream(Stream),
  (
     first(F1, Col, 1) ->                     % if F1 is 1st char on line 1
     write(Stream, `\n   evaluate(`), write(Stream, F1), 
     write(Stream, ` * `), write(Stream, F2), write(Stream, ` + ProdCarry`), 
     write(Stream, PPLino), write(Stream, CarryIn), 
     write(Stream, `, ProdCarry`), write(Stream, PPLino), 
     write(Stream, PPCol), write(Stream, `, `), write(Stream, PPName), 
     write(Stream, `), `) ;                   % F1 is not 1st char

     write(Stream, `\n   evaluate(`), write(Stream, F1), 
     write(Stream, ` * `), write(Stream, F2), write(Stream, ` + ProdCarry`), 
     write(Stream, PPLino), write(Stream, CarryIn), 
     write(Stream, `, ProdCarry`), write(Stream, PPLino), 
     write(Stream, PPCol), write(Stream, `, `), write(Stream, PPName), 
     write(Stream, `), `)
  ).
*/
getVars(Col, Line) -->                        % get list of vars
  ({pos(Char, Col, Line, Wild)} -> validateVar(Char, Wild) ;  []),
  {Line1 is Line - 1},
  ({Line1 > 0} -> getVars(Col, Line1) ;  []).

writeListNames(Stream, []) :-
  write(emptyVarList), nl, !.
writeListNames(Stream, [X]) :- !,
  write(Stream, `'`), write(Stream, X), write(Stream, `'`).
writeListNames(Stream, [X|Rest]) :-
  write(Stream, `'`), write(Stream, X), write(Stream, `'`), 
  write(Stream, `, `), 
  writeListNames(Stream, Rest).

doProd(PPCol) -->
  {getCols(Cols)},
  prodCol(PPCol, PPCol, Cols),                % F1Col = Cols, F2Col = PPCol
  {
     getCapStream(Stream),
     CarryIn is PPCol + 1,
     CarryOut is PPCol,
     barLine(2, BarLine2, WildProd),
     ProdLine is BarLine2 + 1,
     To is BarLine2 - 1,
     (
        PPCol = Cols ->                       % first col
        write(Stream, `\n   evaluate(0 `) ;

        write(Stream, `\n   evaluate(SumCarry`), write(Stream, CarryIn), 
        write(Stream, ' ')
     ),
     sumCol(PPCol, 4, To),                    % sum the PPCol
     pos(SumSymbol, PPCol, ProdLine, WildSum), % get SumSymbol 
     (
        PPCol = 1 ->
        write(Stream, `, 0, `), write(Stream, SumSymbol), 
        write(Stream, `), `), 
        (
           first(SumSymbol, _, To) ->
           write(Stream, `   `), write(Stream, SumSymbol), 
           write(Stream, ` > 0, `) ;

           true
        ) ;

        write(Stream, `, SumCarry`), write(Stream, CarryOut), 
        write(Stream, `, `), write(Stream, SumSymbol), write(Stream, `), `)
     ),
     PPCol1 is PPCol - 1
  },
  validateVar(SumSymbol, WildSum),
  ({PPCol1 > 0} -> doProd(PPCol1) ;  []).     % stop at col 1 

prodCol(PPCol, F1Col, F2Col) -->              % recurse over PPCol
  {CarryCol is PPCol - 1},
  {getCols(Cols)},
  {PPLino is Cols - F2Col + 4},
  {first(_, FirstCol1, 1)},
  {first(_, FirstCol2, 2)},
  (
     {F1Col >= FirstCol1},
     {F1Col =< Cols},
     {F2Col >= FirstCol2} ->
     {pos(F1, F1Col, 1, Wild1)},
     {pos(F2, F2Col, 2, Wild2)},
     validateVar(F1, Wild1),
     validateVar(F2, Wild2),
     check(X),
     {
        (
				pos(ProdName, PPCol, PPLino, WildProd) ;

				Cursor is 10*PPLino + PPCol,
				atomlist_concat(['R', Cursor], ProdName),
				assert(pos(ProdName, PPCol, PPLino, 1))
		  ),

/*
        Cursor is 10*PPLino + PPCol,
        atomlist_concat(['R', Cursor], ProdName),
        (
           pos(ProdName, PPCol, PPLino, WildProd) ->
           true ;

           assert(pos(ProdName, PPCol, PPLino, 1))
        ),
*/
        (first(_, F1Col, 1) -> Flag1 = 1 ;  Flag1 = 0), % F1 is 1st on line 1
        (F1Col = Cols -> Flag2 = 2 ;  Flag2 = 0),       % F1 is 2 if last 
        Flag is Flag1 \/ Flag2,               
        prodEval(Flag, F1, F2, PPCol, PPLino, ProdName)
     },
     validateVar(ProdName, WildProd) ;

     (                                        % factors not in range
        {pos(CarryName, CarryCol, PPLino, WildCarry)} ->
        validateVar(CarryName, WildCarry) ;   % but there is a carry

        []
     )
  ),
  {F1Col1 is F1Col + 1},
  {F2Col1 is F2Col - 1},
  ({F1Col1 =< Cols} -> prodCol(PPCol, F1Col1, F2Col1) ;  []).

member(H, [H|_]).
member(H, [_|T]) :-
  member(H, T).

