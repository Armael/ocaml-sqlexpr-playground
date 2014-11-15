module Sqlexpr = Sqlexpr_sqlite_lwt
module S = Sqlexpr

open Lwt

let init_db db =
  S.execute db
    sql"CREATE TABLE IF NOT EXISTS users(
             id INTEGER PRIMARY KEY,
             login TEXT UNIQUE,
             password TEXT NON NULL,
             name TEXT,
             email TEXT
            );"

let fold_users db f acc =
  S.fold db f acc sqlc"SELECT @s{login}, @s{password}, @s?{email} FROM users"

let insert_user db ~login ~password ?name ?email () =
  S.insert db
    sqlc"INSERT INTO users(login, password, name, email)
         VALUES(%s, %s, %s?, %s?)"
    login password name email

let main =
  let db = S.open_db "toto.db" in

  init_db db >>= fun _ ->

  insert_user db ~login:"armael" ~password:"toto" () >>= fun _ ->
  insert_user db ~login:"foo" ~password:"blbl" ~email:"salut" () >>= fun _ ->

  fold_users db
    (fun () (l, p, e) ->
       Printf.printf "%s - %s - %s\n%!" l p (match e with None -> "None" | Some x -> x)
       |> Lwt.return)
    () >>= fun _ ->

  flush_all ();
  Lwt.return (S.close_db db)

let () =
  Lwt_main.run main
