module WordApp exposing (main)

import Navigation exposing (Location)
import Util exposing ((=>))
import Http
import Task exposing (..)
import Json.Decode as Decode exposing (Value)
import Html as Html exposing (..)
import Html.Styled
import Route exposing (Route)
import Request exposing (..)
import Views.Page as Page
import Page.Login as Login
import Page.Register as Register
import Page.Home as Home
import Page.WordEdit as WordEdit
import Page.WordDelete as WordDelete
import Page.Quizz as Quizz
import Page.NotFound as NotFound
import Data.Session exposing (..)
import Data.Message exposing (..)
import Request exposing (..)
import API exposing (..)
import Ports exposing (..)
import Debug


type Page
    = NotFound
    | Login Login.Model
    | Register Register.Model
    | Home Home.Model
    | WordEdit WordEdit.Model
    | WordDelete WordDelete.Model
    | Quizz



-- MODEL --


type alias Model =
    { messages : List Message
    , session : Session
    , page : Page
    }


init : Value -> Location -> ( Model, Cmd Msg )
init val location =
    setRoute (Route.fromLocation location)
        { messages = []
        , session = (retrieveSessionFromJson val)
        , page = NotFound
        }



-- VIEW --


view : Model -> Html Msg
view model =
    let
        frame =
            Page.frame model.session model.messages
    in
        case model.page of
            Login subModel ->
                Login.view subModel
                    |> frame
                    |> Html.Styled.map LoginMsg
                    |> Html.Styled.toUnstyled

            Register subModel ->
                Register.view subModel
                    |> frame
                    |> Html.Styled.map RegisterMsg
                    |> Html.Styled.toUnstyled

            Home subModel ->
                Home.view subModel
                    |> frame
                    |> Html.Styled.map HomeMsg
                    |> Html.Styled.toUnstyled

            WordEdit subModel ->
                WordEdit.view subModel
                    |> frame
                    |> Html.Styled.map WordEditMsg
                    |> Html.Styled.toUnstyled

            WordDelete subModel ->
                WordDelete.view subModel
                    |> frame
                    |> Html.Styled.map WordDeleteMsg
                    |> Html.Styled.toUnstyled

            Quizz ->
                Quizz.view
                    |> frame
                    |> Html.Styled.map QuizzMsg
                    |> Html.Styled.toUnstyled

            NotFound ->
                NotFound.view
                    |> frame
                    |> Html.Styled.toUnstyled



-- SUBSCRIPTION --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE --


type Msg
    = SetRoute (Maybe Route)
    | LoginMsg Login.Msg
    | RegisterMsg Register.Msg
    | RegisterInit (Result Http.Error String)
    | HomeInit (Result Http.Error (List Word))
    | HomeMsg Home.Msg
    | WordEditInitMsg (Result Http.Error Word)
    | WordEditMsg WordEdit.Msg
    | WordDeleteInitMsg (Result Http.Error NoContent)
    | WordDeleteMsg WordDelete.Msg
    | QuizzMsg Quizz.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updatePage (.page model) msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    case ( page, msg ) of
        ( _, SetRoute route ) ->
            setRoute route model

        ( Login subModel, LoginMsg subMsg ) ->
            let
                ( ( pageModel, pageMsg ), externalMsg ) =
                    Login.update subMsg subModel

                newModel =
                    case externalMsg of
                        Login.NoOp ->
                            model

                        Login.SetSession newSession ->
                            { model | session = newSession }
            in
                { newModel | page = Login pageModel }
                    => Cmd.map LoginMsg pageMsg

        ( Register subModel, RegisterInit subMsg ) ->
            let
                ( ( pageModel, pageMsg ), externalMsg ) =
                    Register.update (Register.InitFinished subMsg) subModel
            in
                { model | page = Register pageModel }
                    => Cmd.map RegisterMsg pageMsg

        ( Register subModel, RegisterMsg subMsg ) ->
            let
                ( ( pageModel, pageMsg ), externalMsg ) =
                    Register.update subMsg subModel
            in
                case externalMsg of
                    Register.NoOp ->
                        { model | page = Register pageModel }
                            => Cmd.map RegisterMsg pageMsg

                    Register.GoLogin ->
                        setRoute (Just Route.Login) model

        ( Home subModel, HomeInit subMsg ) ->
            let
                ( ( pageModel, pageMsg ), externalMsg ) =
                    Home.update model.session (Home.InitFinished subMsg) subModel
            in
                case externalMsg of
                    Home.NoOp ->
                        { model | page = Home pageModel }
                            => Cmd.map HomeMsg pageMsg

                    Home.Logout ->
                        { model | session = (Session Nothing Nothing), messages = ((Message Warning "You got logged out") :: model.messages) }
                            => Cmd.batch [ deleteSession, Route.modifyUrl Route.Login ]

                    Home.ReloadPage ->
                        case model.session.user of
                            Nothing ->
                                { model | page = Home pageModel }
                                    => Cmd.none

                            Just user ->
                                { model | page = Home pageModel }
                                    => Task.attempt HomeInit (Home.init (.session model))

        ( Home subModel, HomeMsg subMsg ) ->
            let
                ( ( pageModel, pageMsg ), externalMsg ) =
                    Home.update model.session subMsg subModel
            in
                case externalMsg of
                    Home.NoOp ->
                        { model | page = Home pageModel }
                            => Cmd.map HomeMsg pageMsg

                    Home.Logout ->
                        { model | session = (Session Nothing Nothing), messages = ((Message Warning "You got logged out") :: model.messages) }
                            => Cmd.batch [ deleteSession, Route.modifyUrl Route.Login ]

                    Home.ReloadPage ->
                        case model.session.user of
                            Nothing ->
                                { model | page = Home pageModel }
                                    => Cmd.none

                            Just user ->
                                { model | page = Home pageModel }
                                    => Task.attempt HomeInit (Home.init (.session model))

        ( WordEdit subModel, WordEditInitMsg subMsg ) ->
            let
                ( ( pageModel, pageMsg ), externalMsg ) =
                    WordEdit.update model.session (WordEdit.WordEditInitFinished subMsg) subModel
            in
                case externalMsg of
                    WordEdit.NoOp ->
                        { model | page = WordEdit pageModel }
                            => Cmd.map WordEditMsg pageMsg

                    WordEdit.Logout ->
                        { model | session = (Session Nothing Nothing), messages = ((Message Warning "You got logged out") :: model.messages) }
                            => Cmd.batch [ deleteSession, Route.modifyUrl Route.Login ]

                    WordEdit.GoHome ->
                        model
                            => Route.modifyUrl Route.Home

        ( WordEdit subModel, WordEditMsg subMsg ) ->
            let
                ( ( pageModel, pageMsg ), externalMsg ) =
                    WordEdit.update model.session subMsg subModel
            in
                case externalMsg of
                    WordEdit.NoOp ->
                        { model | page = WordEdit pageModel }
                            => Cmd.map WordEditMsg pageMsg

                    WordEdit.Logout ->
                        { model | session = (Session Nothing Nothing), messages = ((Message Warning "You got logged out") :: model.messages) }
                            => Cmd.batch [ deleteSession, Route.modifyUrl Route.Login ]

                    WordEdit.GoHome ->
                        model
                            => Route.modifyUrl Route.Home

        ( WordDelete subModel, WordDeleteInitMsg subMsg ) ->
            let
                ( ( pageModel, pageMsg ), externalMsg ) =
                    WordDelete.update model.session (WordDelete.WordDeleteInitFinished subMsg) subModel
            in
                case externalMsg of
                    WordDelete.NoOp ->
                        { model | page = WordDelete pageModel }
                            => Cmd.map WordDeleteMsg pageMsg

                    WordDelete.Logout ->
                        { model | session = (Session Nothing Nothing), messages = ((Message Warning "You got logged out") :: model.messages) }
                            => Cmd.batch [ deleteSession, Route.modifyUrl Route.Login ]

                    WordDelete.GoHome ->
                        model
                            => Route.modifyUrl Route.Home

        ( Quizz, _ ) ->
            ( model, Cmd.none )

        ( _, _ ) ->
            -- Disregard incoming messages that arrived for the wrong page
            model => Cmd.none


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    case maybeRoute of
        Nothing ->
            { model | page = NotFound }
                => Cmd.none

        Just (Route.Login) ->
            { model | page = Login Login.initialModel }
                => Cmd.none

        Just (Route.Register) ->
            { model | page = Register Register.initialModel }
                => Task.attempt RegisterInit Register.init

        Just (Route.Logout) ->
            { model | session = (Session Nothing Nothing) }
                => Cmd.batch [ deleteSession, Route.modifyUrl Route.Login ]

        Just (Route.Home) ->
            let
                newModel =
                    { model | page = Home Home.initialModel }
            in
                case model.session.user of
                    Nothing ->
                        newModel
                            => Cmd.none

                    Just user ->
                        newModel
                            => Task.attempt HomeInit (Home.init (.session model))

        Just (Route.WordEdit wordId) ->
            let
                newModel =
                    { model | page = WordEdit WordEdit.initialModel }
            in
                case model.session.user of
                    Nothing ->
                        newModel
                            => Cmd.none

                    Just user ->
                        newModel
                            => Task.attempt WordEditInitMsg (WordEdit.init (.session model) wordId)

        Just (Route.WordDelete wordId) ->
            let
                newModel =
                    { model | page = WordDelete (WordDelete.Model wordId) }
            in
                case model.session.user of
                    Nothing ->
                        newModel
                            => Cmd.none

                    Just user ->
                        newModel
                            => Task.attempt WordDeleteInitMsg (WordDelete.init (.session model) wordId)

        Just (Route.Quizz) ->
            { model | page = Quizz } => Cmd.none



-- MAIN --


main : Program Value Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
