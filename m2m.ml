module Sqlexpr = Sqlexpr_sqlite_lwt
module S = Sqlexpr
open Lwt

let init_db db =
  S.execute db
    sql"CREATE TABLE IF NOT EXISTS names(
          name_id INTEGER PRIMARY KEY,
          name TEXT NOT NULL UNIQUE
        );" >>= fun _ ->

  S.execute db
    sql"CREATE TABLE IF NOT EXISTS tags(
          tag_id INTEGER PRIMARY KEY,
          tag TEXT NOT NULL UNIQUE
        );" >>= fun _ ->

  S.execute db
    sql"CREATE TABLE IF NOT EXISTS names_to_tags(
          name_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL
        );"

let add_tag db tag =
  S.select_one_maybe db sqlc"SELECT @L{tag_id} FROM tags WHERE tag = %s" tag >>= fun res ->
  match res with
  | None ->
    S.insert db sqlc"INSERT INTO tags(tag) VALUES(%s)" tag
  | Some id ->
    Lwt.return id

let add_name db name =
  S.select db sqlc"SELECT @L{name_id} FROM names WHERE name = %s" name >>= fun res ->
  match res with
  | [] ->
    S.insert db sqlc"INSERT INTO names(name) VALUES(%s)" name
  | [id] ->
    Lwt.return id
  | _ -> assert false
  
let insert_tagged_name db name tags =
  Lwt_list.map_s (add_tag db) tags >>= fun tag_ids ->
  add_name db name >>= fun name_id ->
  Lwt_list.iter_s (fun tag_id ->
      try 
        S.insert db sqlc"INSERT INTO names_to_tags(name_id, tag_id)
          VALUES(%L, %L)"
          name_id tag_id >|= fun _ -> ()
      with S.Error(_) -> Lwt.return ()
    ) tag_ids

let names_with_tag db tag =
  add_tag db tag >>= fun tag_id ->
  S.select db sqlc"SELECT @s{name} FROM names JOIN names_to_tags
                   WHERE names.name_id = names_to_tags.name_id
                   AND names_to_tags.tag_id = %L"
    tag_id

let main =
  let db = S.open_db "m2m.db" in
  init_db db >>= fun _ ->

  insert_tagged_name db "toto" ["foo"; "bar"; "baz"] >>= fun _ ->
  insert_tagged_name db "tata" ["blbl"; "bar"] >>= fun _ ->
  insert_tagged_name db "titi" ["foo"; "slsl"] >>= fun _ ->

  names_with_tag db "foo" >>= fun l ->
  List.iter print_endline l;

  Lwt.return (S.close_db db)

let () =
  Lwt_main.run main
