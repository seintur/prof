let rec print_ue_list list =
  match list with
  | [] -> ()
  | ue::_ -> (
    Printf.printf "%d : %s\n" (Libprof.get_UE_id ue)(Libprof.get_UE_title ue);
    print_ue_list (List.tl list);
  )
    
let rec print_tp_list list =
  match list with
  | [] -> ()
  | tp::_ -> ( 
    Printf.printf "%d : %s (%s) \n" 
      (Libprof.get_TP_id tp)
      (Libprof.get_TP_title tp)
      (match (Libprof.get_TP_status tp) with 
      | true -> "Ouvert" | _ -> "Ferme");
    print_tp_list (List.tl list);
  )

let ask_password s =
  print_string s;
  flush stdout;

  (* On demande au shell de ne pas répéter les charactères entrés par l'utilisateur *)
  let exit_code = Sys.command "stty -echo" in
  if (exit_code <> 0) then
    failwith "Ask_password error with stty";

  let tmp = input_line stdin in
  print_newline ();
  (* On réactive l'echo *)
  let exit_code = Sys.command "stty echo" in
  if (exit_code <> 0) then
    failwith "Ask_password error with stty"
  else
    tmp



let ask s = 
  print_string s;
  flush stdout;
  input_line stdin
    
let _ =
  
  begin

    try
      let login = ask "login ? " in
      let password = ask_password "password (hidden input) ? " in
      print_newline ();
      let c = Libprof.init_connection () in
      Libprof.log c login password;
      let ue_list = Libprof.get_UE_list c in
      print_newline ();
      print_ue_list ue_list;
      let ue_id = int_of_string (ask "ue id ? ") in
      let tmp = Libprof.get_TP_list c ue_id in
      print_newline ();
      print_tp_list tmp;
      let user_respond = (ask "[u|d] tp id ? (u to upload a file, d to delete a file)\n") in
      let what_we_want = Str.regexp"\\(u\\|d\\)\\([0-9]+\\)" in
      if Str.string_match what_we_want user_respond 0 then
	(
	  let tp_id = int_of_string (Str.matched_group 2 user_respond) in
	  let action = Str.matched_group 1 user_respond in
	  match action with
	  | "u" ->     (* check arguments *)
	    if Array.length Sys.argv != 2 then
	      (
		print_string  "usage : prof archive.tar.gz\n No argument found, exciting, nothing done\n";
		failwith "Missing argument"
	      )
	    else
	      Libprof.upload c tp_id Sys.argv.(1);
	  | "d" -> Libprof.delete c tp_id;
	  | _ -> failwith "Didn't get what you mean !"
	);
    with
    | Curl.CurlException (reason, code, str) ->
      Printf.printf "Error: %s\n" str
    | Failure s ->
      Printf.printf "Caught exception: %s\n" s
  end;
  Curl.global_cleanup ()
