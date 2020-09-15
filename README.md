# lua-regexp

Matching strings against regular expressions using Brzozowski's
derivatives.  Also, the package includes a regular expression parser,
derived from the following "Simple Grammar":

                    
    E  :=  w$       
        |  w( G E   
        |  w+ E     
    G  :=  w)       
        |  w)*      
        |  w( G G   
        |  w+ G     

where `w` is a sequence (possibly empty) of letters, character classes,
and their iterations, e.g., `w = a[^a-z]*b*`. 


E.g.,

    $> lua
    Lua 5.3.5  Copyright (C) 1994-2018 Lua.org, PUC-Rio
    > RE = dofile("re.lua")
    > re = RE.parse("([a-z]*[a-zA-Z])*[A-Z]*[a-z]")
    > RE.matches(re, "aaaaaaaaaaaaaaaaaaaAaaaaaaaaaaaAAAAaaaaaaaaaaaaaaaaaAaaaZa1")
    false
    > RE.matches(re, "aaaaaaaaaaaaaaAaaaaaaaaaaaaaaaaAAAAaaaaaaaaaaaaaaaaaaaAaaaZa")
    true
    
