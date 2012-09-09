
# Hyphenation

This software implements hyphentation of words for Objective Caml based on
the algorithm implemented in TeX and using the hyphenation patterns
provided for TeX.

## Requirements and Compilation

To compile the software from source code you need:

* A Unix system like Linux or MacOS X. Objective Caml also is available
  for other platforms and the code is portable but the build process
  makes no attempt to support building the code on non-Unix platforms.
* Objective Caml
* Make
* Lipsum (http://github.com/lindig/lipsum). This is a tool to support
  literate programming and is needed to extract the source code from this
  literate program. Lipsum is implemented in Objective Caml as well and you
  could add it as as Git submodule.

To build the software it should suffice to run Make. Please take a look at
the `Makefile`. It supports downloading and building Lipsum.

    $ make

## Demo 

Running Make builds a small demo application that can be used to hyphenate
words from a text file or the command line.

    ./demo.native Compilation Requirements
    Com-pi-la-tion
    Re-quire-ments

    ./demo.native -h
    demo.native -f file.txt
    demo.native word .. 

    demo.native reads words from a file or the the command line and
    emits them hyphenated to stdout.

## References

TeX's hyphenation algorithm is detailed in _The TeXbook_ by Donald Knuth in
Appendix H.

## Copyright

Copyright (c) 2012, Christian Lindig <lindig@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

1.  Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
2.  Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

## Encodings

This code works only with encodings where a character corresponds to a
byte. 

## Hyphenate -- The Interface

The core algorithm is implemented in module Hyphenate with an accompanying
interface. 

Hyphenation is language specific and requires to load hyphenation patterns
from a file using `load` before words can be hyphenated using `hyphenate`.
A language value is a mutable abstraction.  `hyphenate` splits a given
word into disjoint substrings:

<<hyphenate.mli>>=
exception Error of string

type t                          (* mutable *)   
type path = string              (* file path *)

val make: unit -> t             (* create empty value *)
val add:  t -> string -> unit   (* add a pattern to a language *)

val load: path -> t             (* may raise Error *)
val dump: t -> unit             (* for debugging *)

val hyphenate: t -> string -> string list
@

## Hyphenation Patterns

TeX encodes language-specific hyphenation patterns in files with one pattern
per line:

    .ba5na
    .bas4e
    .ber4
    .be5ra

A pattern is a sequence of letters that are interspersed with digits. A
digit greater zero indicates (roughly) a good hyphenation point.  In the
above format, digit `0` may be omitted for brevity. Hence, the patterns
above could be expanded to:

    .0b0a5n0a0
    .0b0a0s4e0
    .0b0e0r40
    .0b0e5r0a0

A dot at the beginning or end of a pattern designates the beginning or end
of a word. Before a word to be hyphenated is matched against a pattern, it
is prefixed and affixed with a dot such that pattern with a dot matches
only the beginning or end of a word.

A pattern file may contain comments. A comment (just like in TeX) starts
with a `%` and reaches until the end of the line.

The file `hyphen.tex` with hyphenation patterns for US English is from the
TeX distribution at
[www.tex.ac.uk](http://www.tex.ac.uk/tex-archive/macros/plain/base/hyphen.tex).
More language-specific patterns can be found at
[tug.org/tex-hyphen](http://tug.org/tex-hyphen)

## Reading Patterns -- The Interface

To read a pattern file we use a lexical scanner. The scanner implements a
function `read` that returns the next pattern. 

<<hyphenate_reader.mli>>=
exception Error of string       (* reports syntax errors in patterns*)
type entry =
    | EOF                       (* end of file *)
    | Pattern of string         (* pattern *)

val read:   Lexing.lexbuf -> entry (* may raise Error *)
val words:  Lexing.lexbuf -> string list (* for testing *)
@

## Reading Patterns -- The Implementation

Below is the general organization of a scanner specification for the
OCamlLex scanner generator.

<<hyphenate_reader.mll>>=
{
    <<prolog>>
}
<<rules>>
{
    <<epilog>>
}

@ The prolog contains generally useful definitions that can be used
in the rest of the file.

<<prolog>>=
exception Error of string
let error fmt   = Printf.kprintf (fun msg -> raise (Error msg)) fmt

type entry = EOF | Pattern of string

let get         = Lexing.lexeme
let (@@) f x    = f x       (* function application *)
let (@.) f g x  = f (g x)   (* function composition *)

<<rules>>=
let digit       = ['0'-'9']
let lowercase   = ['a'-'z']
let uppercase   = ['A'-'Z']
let alpha       = lowercase | uppercase
let dot         = '.'
let pat         = dot? digit? (lowercase digit?)+ dot?
let comment     = '%' [^'\n']* '\n'
let ws          = [' ' '\t' '\r' '\n']

@ Rule `token`  recognizes a pattern as it is in a file. 
attempt to add the implicit `0` digits or to split letters and digits.

<<rules>>=
rule token = parse
    eof         { EOF }
  | ws+         { token lexbuf }
  | comment     { token lexbuf }
  | pat         { Pattern (get lexbuf) }
  | _           { error "illegal pattern: %s" @@ get lexbuf }

@ Rule `words`  splits the input into words by capturing sequences of
letters and returns them lowercased in a list. Such words are collected
into a list.  This list must be reversed before it is returned.  Be aware
that only `a` to `z` and `A` to `Z` are considered letters that make up
words. The `words` scanner is used only by the demo application to split
a text file into words but is not used by module Hyphenate.

<<rules>>=
and words ws = parse
     eof        { List.rev ws }
  |  alpha+     { words ((String.lowercase @@ get lexbuf) :: ws) lexbuf }
  |  _          { words ws lexbuf }  (* skip *)   


@ Function `read` reads the next pattern from the file and splits into
two components. Function `words` returns the words in a file (in lower
case).

<<epilog>>=
let read:   Lexing.lexbuf -> entry          = token
let words:  Lexing.lexbuf -> string list    = words []
@

## Hyphenate -- The Implementation

This module implements the hyphenation algorithm using hyphenation
patterns. Hyphenation patterns for a language are simply stored in a
hashtable mapping strings of length _n_ to _n+1_ possible hyphenation
points. We also remmember the longest pattern such that we can avoid
searching for any pattern that exceeds the lengths of the longest stored
pattern.

<<hyphenate.ml>>=
type path       = string      (* a file path *)
type t   = 
    { patterns:             (string, int array) Hashtbl.t (* key, value *)
    ; mutable maxlen:       int (* longest key in patterns *)
    ; mutable minlen:       int (* shortest key in patterns *)
    }

let make () =                           (* create empty value *)
    { patterns  =   Hashtbl.create 4999 (* a prime number *)
    ; maxlen    =   0
    ; minlen    =   max_int                
    }

<<hyphenate.ml>>=
exception Error of string
let error msg = raise (Error msg)

let debug fmt   = Printf.kprintf (fun msg -> prerr_string msg) fmt
let debug fmt   = Printf.kprintf (fun msg -> ()) fmt

@ Some small utilities.

<<hyphenate.ml>>=
let (@.) f g x  = f (g x)   (* function composition *)
let (@@) f x    = f x 

@ `finally f x cleanup` function provides resource cleanup in the presence
of exceptions: `f x` is computed as a result and `cleanup x` is guaranteed
to run afterwards. (In many cases `cleanup` will not use its argument `x`
but it can be convenient to have access to it.)

<<hyphenate.ml>>=
type 'a result = Success of 'a | Failed of exn
let finally f x cleanup = 
    let result =
        try Success (f x) with exn -> Failed exn
    in
        cleanup x; 
        match result with
        | Success y  -> y 
        | Failed exn -> raise exn

@ Below are functions that split a pattern as it is read from a file
into a pattern value.

First some predicates to classify characters as letters and digits and
computer the integer value of a digit.
<<hyphenate.ml>>=
let is_digit = function
    | '0'..'9' -> true
    | _        -> false

let is_letter = not @. is_digit 

let int_of (c:char): int = 
    assert ('0' <= c && c <= '9');
    Char.code c - Char.code '0'

@ Function `foldstr f zero str` iterates over string `str` from left to
right and applies `f` to each character and an intermediate value. The
initial intermediate value is `zero` and the next one is the value returned
by `f` in the previous iteration.

<<hyphenate.ml>>=
let foldstr f zero str =
    let limit = String.length str in
    let rec loop i acc = 
        if   i = limit 
        then acc 
        else loop (i+1) (f acc str.[i])
    in
        loop 0 zero

@ `Letters` counts the number of letters in a string.

<<hyphenate.ml>>=
let letters (word:string): int = 
    foldstr (fun n c -> if is_letter c then n+1 else n) 0 word

@ Function `split` takes a pattern as it is read from a pattern file and
splits it into a pattern -- a string of length _n_ and an array of size
_n+1_. For a letter at position _i_ in the string, the array indices _i_
and _i+1_ assign a value to points before and after the letter that
indicates its suitability as a breakpoint. The function first creates a
string of spaces and an array initialized with zeroes and fills both as it
scans the pattern that was read from the file. We rely on the scanner that
the `texword` argument has a suitable format.

<<hyphenate.ml>>=
let split (texword:string): string * int array =
    let n      = letters texword in
    let word   = String.make n ' ' in
    let breaks = Array.create (n+1) 0 in
    let scan i c =
        if is_letter c
        then (  word.[i] <- c       ; i+1)
        else (breaks.(i) <- int_of c; i  )
    in
        ( ignore (* int *) (foldstr scan 0 texword)
        ; word, breaks
        )

<<hyphenate.ml>>=
let add (t:t) pattern: unit =
    let word, breaks = split pattern in
        ( Hashtbl.add t.patterns word breaks
        ; t.maxlen <- max t.maxlen (String.length word)
        ; t.minlen <- min t.minlen (String.length word)
        )

@ The `slide` function takes a string and a function `f` and applies it to
all substrings of length `n`, starting on the left of the string. Hence, a
window of size `n` is slid over the string and each content is passed to
`f`. In addition, `f` is passed the index of the first character of the
substring.

<<hyphenate.ml>>=
let slide (n:int) (str:string) (f:int -> string -> unit): unit =
    assert (n > 0);
    assert (n <= String.length str);
    for i = 0 to String.length str - n do
        f i (String.sub str i n)
    done    

@ The basic idea to compute hyphenation points using patterns is as follows:
given a string, we slide windows of increasing size 1, 2, 3, ... over this
string. Every window content is taken as a key to look up an assoiciated
array of integers that assigns numbers to every point before, after, and
within the string, that is, all possible hyphenation points. For a window
of size _m_ the integer array has size _m+1_, which is the number of
hypheneation points for a string of size _m_. 

When we desire to hyphenate a word of size _n_, the various sliding windows
retrieve associated hyphenation points which are combined into one array of
size _n+1_ such that each hyphenation point has an integer assigned.

A short array of size _m+1_ is combined with a larger array of size _n+1_
point by point: the large array starts with all zeros. As the smaller array
is slid over the large array, the value in the large array at position _i_
is the maximum of the existing value and the value in the smaller array.

Adding a small integer array to a large array is implemented by function
`combine`.  It takes a `small` and a `large` array as arguments and the
index `i` of the element in the large array that is aligned with the first
element (0) of the smaller array. Since we are dealing with arrays, the
result is an updated large array. 

<<hyphenate.ml>>=
let combine ~(first:int) ~(small:int array) ~(large:int array): unit =
    assert (Array.length small + first <= Array.length large);
    for i = first to first + Array.length small - 1 do
        large.(i) <- max small.(i-first) large.(i)
    done    

@ Function `load` reads a pattern file for a language and returns a
`language` value.  We make sure that the file gets closed even if some
exception is raised (most likely due to syntax errors detected in the
scanner).

<<hyphenate.ml>>=
let load' io: t =
    let lexbuf      = Lexing.from_channel io                in
    let t           = make ()                               in
    let rec loop lb =
        match Hyphenate_reader.read lb with
            | Hyphenate_reader.EOF -> t
            | Hyphenate_reader.Pattern(pattern) -> 
                ( add t pattern
                ; loop lb 
                )
    in
        loop lexbuf

let load (path:path): t =
    let io = try open_in path with Sys_error(msg) -> error msg 
    in
        finally load' io close_in

@ Hyphenation by splitting a word into substrings can finally happen when
we know about the hyphenation points. For a word of size _n_ there are
_n+1_ potential hyphenation points (including before and after the word).
Array `breaks` of size _n+1_ assigns a value to each hyphenation point. A
possible hyphenation is found, if the assigned value is odd. (I actually
don't know what this is and would probably have to read the original paper
as it is not explained in _The TeXbook_)

<<hyphenate.ml>>=
let is_hp n = n > 0 && n mod 2 <> 0

let split (word:string) (breaks:int array) =
    assert (Array.length breaks = String.length word + 1);
    let limit = Array.length breaks - 2 in
    let rec next_hp i = 
        if is_hp breaks.(i) or i >= limit then i else next_hp (i+1) in
    let rec loop i acc =
        let n = next_hp i in
            if  n >= limit 
            then String.sub word (i-1) (n-i+1) :: acc
            else loop (n+1) (String.sub word (i-1) (n-i+1) :: acc)
    in
        List.rev (loop 2 [])

@ For debugging, we join a word and its break points into a string again
that can be easily printed.

<<hyphenate.ml>>=
let join (word:string) (breaks:int array): string =
    assert (Array.length breaks = String.length word + 1);
    let i2c i = Char.chr (i + Char.code '0') in
    let str = String.make (Array.length breaks + String.length word) ' ' in
    for i = 0 to String.length word - 1 do
        ( str.[i*2]   <- i2c breaks.(i)
        ; str.[i*2+1] <- word.[i]
        )
    done; 
    str.[String.length word * 2] <- i2c breaks.(String.length word);
    str

@ To hyphenate a word, we put a dot `.` at the beginning and end and use a
sliding window to find all matching patterns in the pattern dictionary.
The result is an array that tells us about good hyphenation points.  When a
matching pattern is found, the corresponding hyphenation points are
combined with the ones already found. We try to find all patterns in the
dictionary up to the maximum pattern length or the length of the word,
whatever is shorter.

<<hyphenate.ml>>=
let hyphenate t (word:string): string list =
    let word   = "." ^ word ^ "." in
    let len    = String.length word in
    let breaks = Array.make (len + 1) 0 in
    let lookup pos substr:unit =
        ( debug "%s%s\n" (String.make pos ' ') substr
        ; combine pos (Hashtbl.find t.patterns substr) breaks 
        ; debug "%s\n" (join word breaks)
        ) in
    let lookup' pos substr = try lookup pos substr with Not_found -> ()
    in
        for i = t.minlen to min t.maxlen len do
            slide i word lookup'
        done;
        debug "%s\n" (join word breaks);
        split word breaks

<<hyphenate.ml>>=
let dump t =
    let print key value =
        Printf.printf "%s %s\n" key (join key value)
    in    
        Hashtbl.iter print t.patterns
@

## Demo Client

We provide a small demo client.

<<demo.ml>>=
exception Error of string

let error msg = raise (Error msg)
let (@@) f x  = f x 

@ `finally f x cleanup` function provides resource cleanup in the presence
of exceptions: `f x` is computed as a result and `cleanup x` is guaranteed
to run afterwards. (In many cases `cleanup` will not use its argument `x`
but it can be convenient to have access to it.)

<<demo.ml>>=
type 'a result = Success of 'a | Failed of exn
let finally f x cleanup = 
    let result =
        try Success (f x) with exn -> Failed exn
    in
        cleanup x; 
        match result with
        | Success y  -> y 
        | Failed exn -> raise exn


<<demo.ml>>=
let usage this =
    List.iter prerr_endline
    [ this ^ " -f file.txt          hypenate words in file.txt"
    ; this ^ " word ..              hyphenate arguments"
    ; this ^ " -h                   emit help"
    ; this ^ "-d                    emit hyphenation patterns" 
    ; ""
    ; this ^ " reads words from a file or the the command line and"
    ; "emits them hyphenated to stdout. Before hyphenation, words are"
    ; "turned to lower case."
    ; ""
    ; "(c) 2012 Christian Lindig <lindig@gmail.com>"
    ; "https://github.com/lindig/ocaml-hyphenate"
    ]

@ `process` hyphenates a word, joins the parts together using a hyphen and 
emits it.

<<demo.ml>>=
let process lang word = 
    print_endline @@ String.concat "-" @@ Hyphenate.hyphenate lang word

let words' io       = Hyphenate_reader.words @@ Lexing.from_channel io
let words_in path   = finally words' (open_in path) close_in    

let main () =
    let argv        = Array.to_list Sys.argv in
    let this        = Filename.basename (List.hd argv) in
    let args        = List.tl argv in    
    let language    = Hyphenate_us.t in
        match args with
        | ["-f"; path]  -> List.iter (process language) (words_in path)
        | "-h" :: _     -> usage this
        | ["-d"]        -> Hyphenate.dump Hyphenate_us.t
        | word :: _     -> List.iter (process language) 
                            (List.map String.lowercase args)         
        | _             -> usage this

let _ = main (); exit 0
@        
