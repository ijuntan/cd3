{%
  Test_1 program
%}

% declare variables with type and init
const a: int := 5
var n: int := 10

% declare variables with type only
var index: int
var sum: int

% declare variables with init only
var c := 0
const hellow := "Hello world"

% function declaration random
function random (a: int, b: int) : int
  % declare variables in function
  var d :int := 500
  
  % assign to variables
  sum := 0
  
  % for loop
  for id: 1 .. 8 
   sum := sum + id
  end for
  
  put "a is "
  put a
  skip

  put "b is "
  put b
  skip

  put "d is "
  put d
  skip

  put "sum is "
  put sum
  skip
  result a+b*d/sum
end random

% procedure declaration hello world
procedure hello()
  put "Hello World"
  skip
end hello

% assign function invocation
c := random(a, 3)

% nested if statement
if c < 40 then
  put "c is "
  put c
  skip
else
  put "c is "
  put -c
  skip

  put "n is "
  put n
  skip
  if c not= n then
    var a :int := 100
    put "a is "
    put a
    skip
  end if

end if

% begin statement
begin
  var a :int
  a := n
	
  % procedure invocation
  hello()
end

% loop statement
put "loop stop until index is n= "
put n
skip

loop
  sum := sum + index
  index := index + 1
  put "current index is "
  put index
  skip
  exit when index = n
end loop

% put expr
put hellow
skip


