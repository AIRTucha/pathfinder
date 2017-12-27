module ParserTest exposing (..)


import Expect exposing (Expectation)
import Test exposing (..)
import Parser exposing (..)
import Maybe

testStr = "string"

suite : Test
suite =
    describe "Parser"
        [ describe "Build a tree"
            [ test "path and int" <|
                \_ -> 
                    p testStr </> int
                        |> Expect.equal ( URLFork '/' (ParsePath testStr) (URLNode ParseInt) )
            , test "float and path" <|
                \_ -> 
                    float </> p testStr 
                        |> Expect.equal ( URLFork '/' ParseFloat (URLNode <| ParsePath testStr) )
            , test "complex path with single divider" <|
                \_ -> 
                    float </> int </> p testStr 
                        |> Expect.equal ( URLFork '/' ParseFloat <| URLFork '/' ParseInt (URLNode <| ParsePath testStr) )
            , test "complex path" <|
                \_ -> 
                    float </> p testStr <?> int
                        |> Expect.equal ( URLFork '/' ParseFloat <| URLFork '?' (ParsePath testStr) (URLNode <| ParseInt) )
            , test "verty comple path" <|
                \_ ->
                    (int </> int) <?> (float <&> p testStr)
                        |> Expect.equal 
                            ( URLFork '/' ParseInt <| 
                                URLFork '?' ParseInt <| 
                                    URLFork '&' ParseFloat <|
                                        URLNode (ParsePath testStr) )
            , test "path from two forks" <|
                \_ ->
                    (URLFork '/' ParseInt <| URLNode ParseInt ) <?> (URLFork '&' ParseFloat <| URLNode <| ParsePath testStr )
                        |> Expect.equal 
                            ( URLFork '/' ParseInt <| 
                                URLFork '?' ParseInt <| 
                                    URLFork '&' ParseFloat <|
                                        URLNode (ParsePath testStr) )
            ]
        , describe "Split string once"
            [ test "split string by /" <|
                \_ ->
                    break '/' "some/value"
                        |> Expect.equal ( Just ("some", "value") )
            , test "split string by multiple /" <|
                \_ ->
                    break '/' "some/value/someother"
                        |> Expect.equal ( Just ("some", "value/someother") )
            , test "empty string" <|
                \_ ->
                    break '/' ""
                        |> Expect.equal Nothing
            , test "no splitter" <|
                \_ ->
                    break '/' "some.value"
                        |> Expect.equal Nothing
            , test "just splitter" <|
                \_ ->
                    break '/' "/"
                        |> Expect.equal ( Just("","") )
            ]
        , describe "Parse path"
            [ describe "Path"
                [ describe "Correct"
                    [ test "just path" <|
                        \_ ->
                            testStr   
                                |> parser (p testStr)
                                |> Expect.equal Succes
                    , test "two paths" <|
                        \_ ->
                            testStr ++ "/" ++ testStr
                                |> parser (p testStr </> p testStr)
                                |> Expect.equal Succes
                    , test "path and int" <|
                        \_ ->
                            testStr ++ "/10"
                                |> parser (p testStr </> int)
                                |> Expect.equal ( Interger 10 ) 
                    , test "path and float" <|
                        \_ ->
                            testStr ++ "/3.1415"
                                |> parser (p testStr </> float)
                                |> Expect.equal ( Floating 3.1415 )
                    ]
                , describe "Error" 
                    [ test "Incorrect path" <|
                        \_ ->
                            let
                                strErr = testStr ++ "Error"
                            in
                                strErr
                                    |> parser (p testStr)
                                    |> Expect.equal ( Failure <| testStr ++ " is not " ++ strErr )
                    , test "Incorrect path after divider" <|
                        \_ ->
                            let
                                str1   = testStr ++ "1"
                                strErr = testStr ++ "Error"
                            in
                                str1 ++ "/" ++ strErr
                                    |> parser ( p str1 </> p testStr )
                                    |> Expect.equal ( Failure <| testStr ++ " is not " ++ strErr )
                    , test "Incorrect devider between paths" <|
                        \_ ->
                            let
                                str1 = testStr ++ "1"
                                str2 = testStr ++ "2"
                            in
                                str1 ++ "/" ++ str2
                                    |> parser (p str1 <&> p str2)
                                    |> Expect.equal (Failure <| str1 ++ "& is not " ++ str1 ++ "/")     
                    ]
                ]
                , describe "Integer"
                    [ describe "Correct"
                        [ test "single int" <|
                            \_ ->
                                "10"
                                    |> parser int 
                                    |> Expect.equal ( Interger 10 ) 
                        , test "two ints" <|
                            \_ ->
                                "10/9"
                                    |> parser  (int </> int) 
                                    |> Expect.equal ( MultyValue <| Interger 10 :: Interger 9 :: [] )
                        , test "int and path" <|
                            \_ ->
                                "9/" ++ testStr
                                    |> parser (int </> p testStr)
                                    |> Expect.equal ( Interger 9 )
                        , test "int and float" <|
                            \_ ->
                                "10/9.123"
                                    |> parser  (int </> float) 
                                    |> Expect.equal ( MultyValue <| Interger 10 :: Floating 9.123 :: [] )
                        ]
                    , describe "Error"
                        [ test "Incorrect int" <|
                            \_ ->
                                "9.14"
                                    |> parser int
                                    |> Expect.equal (Failure "could not convert string '9.14' to an Int")
                        , test "Incorrect separator between ints" <|
                            \_ ->
                                "10?43"
                                    |> parser (int </> int)
                                    |> Expect.equal ( Failure <| "10?43 does not contain /")
                        , test "Incorrect int after devider" <|
                            \_ ->
                                "5&a3"
                                    |> parser (int <&> int)
                                    |> Expect.equal ( MultyValue <| Interger 5 :: Failure "could not convert string 'a3' to an Int" :: [] )
                        ]
                    ]
                , describe "Floating"
                    [ describe "Correct"
                        [ test "single float" <|
                            \_ ->
                                "10.34"
                                    |> parser float 
                                    |> Expect.equal ( Floating 10.34 ) 
                        , test "two floats" <|
                            \_ ->
                                "10.45/9.18"
                                    |> parser  (float </> float) 
                                    |> Expect.equal ( MultyValue <| Floating 10.45 :: Floating 9.18 :: [] )
                        , test "float and path" <|
                            \_ ->
                                "3.14/" ++ testStr
                                    |> parser (float </> p testStr)
                                    |> Expect.equal ( Floating 3.14 )
                        , test "float and int" <|
                            \_ ->
                                "10.435/9"
                                    |> parser  (float </> int) 
                                    |> Expect.equal ( MultyValue <| Floating 10.435 :: Interger 9 :: [] )
                        ]
                    , describe "Error"
                        [ test "Incorrect float" <|
                            \_ ->
                                "a9.43"
                                    |> parser float
                                    |> Expect.equal (Failure "could not convert string 'a9.43' to a Float")
                        , test "Incorrect separator between ints" <|
                            \_ ->
                                "10.5?43.4"
                                    |> parser (float </> float)
                                    |> Expect.equal ( Failure <| "10.5?43.4 does not contain /")
                        , test "Incorrect float after devider" <|
                            \_ ->
                                "5.4&a3.9"
                                    |> parser (float <&> float)
                                    |> Expect.equal ( MultyValue <| Floating 5.4 :: Failure "could not convert string 'a3.9' to a Float" :: [] )
                        ]
                    ]
            ]
        ]