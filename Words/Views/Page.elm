module Views.Page exposing (frame)

import Data.Session exposing (AuthUser, Session)
import Data.Message exposing (..)
import API exposing (User)
import Route as Route exposing (..)
import IziCss exposing (..)
import Views.Messages exposing (..)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)


frame : Session -> List Message -> Html msg -> Html msg
frame session listMessages content =
    div [ bodyFrame ]
        [ viewHeader session
        , div [ mainFrame ] [ viewMessages listMessages, content ]
        , viewFooter
        ]


viewHeader : Session -> Html msg
viewHeader session =
    div [ headerFrame ]
        [ div [ leftHeaderFrame ] []
        , div [ centerHeaderFrame ]
            [ h1 [ titleCss ]
                [ img [ logo, src "/ressources/dictionnary.logo.png" ] []
                , text "IziDict.com"
                ]
            ]
        , div [ rightHeaderFrame ] [ viewNav session ]
        ]


viewMessages : List Message -> Html msg
viewMessages listMessages =
    div []
        [ ul [] (List.map viewMessageLi listMessages)
        ]


viewFooter : Html msg
viewFooter =
    div [ bottomFrame ]
        [ p [] [ text "made with ❤ from ❤ WAW ❤" ] ]


viewNav : Session -> Html msg
viewNav session =
    case session.user of
        Just user ->
            nav []
                [ a [ Route.href Route.Home, whiteLink ] [ text "Go home" ]
                , a [ Route.href Route.Logout, whiteLink ] [ text "- Logout -" ]
                ]

        Nothing ->
            nav
                []
                [ a [ Route.href Route.Register, whiteLink ] [ text "- REGISTER -" ] ]
