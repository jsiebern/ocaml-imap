(* The MIT License (MIT)

   Copyright (c) 2015-2018 Nicolas Ojeda Bar <n.oje.bar@gmail.com>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE. *)

open Sexplib.Std
open Common

module Date = struct
  type t =
    {
      day: int;
      month: int;
      year: int;
    } [@@deriving sexp]

  let to_string {day; month; year} =
    let months =
      [|
        "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun";
        "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec";
      |]
    in
    Printf.sprintf "%2d-%s-%4d" day months.(month) year

  let encode d =
    Encoder.raw (to_string d)
end

module Time = struct
  type t =
    {
      hours: int;
      minutes: int;
      seconds: int;
      zone: int;
    } [@@deriving sexp]

  let to_string {hours; minutes; seconds; zone} =
    Printf.sprintf "%02d:%02d:%02d %c%04d" hours minutes seconds
      (if zone >= 0 then '+' else '-') (abs zone)
end

module MessageAttribute = struct
  type t =
    | FLAGS of Flag.t list
    | ENVELOPE of Envelope.t
    | INTERNALDATE of string (* Date.t * Time.t *)
    | RFC822 of string
    | RFC822_HEADER of string
    | RFC822_TEXT of string
    | RFC822_SIZE of int
    | BODY of MIME.Response.t
    | BODYSTRUCTURE of MIME.Response.t
    | BODY_SECTION of MIME.Section.t * string option
    | UID of int32
    | MODSEQ of int64
    | X_GM_MSGID of int64
    | X_GM_THRID of int64
    | X_GM_LABELS of string list [@@deriving sexp]
end

type 'a t =
  | FLAGS : Flag.t list t
  | ENVELOPE : Envelope.t t
  | UID : uid t
  | X_GM_MSGID : int64 t
  | X_GM_THRID : int64 t
  | X_GM_LABELS : string list t
  | RFC822 : string t
  | RFC822_HEADER : string t
  | RFC822_SIZE : int t
  | PAIR : 'a t * 'b t -> ('a * 'b) t
  | MAP : ('a -> 'b) * 'a t -> 'b t

let flags = FLAGS
let map f x = MAP (f, x)
let tuple3 x y z = MAP ((fun (x, (y, z)) -> x, y, z), PAIR (x, PAIR (y, z)))

module Request = struct
  open Encoder

  type nonrec t = t

  let envelope = raw "ENVELOPE"
  let internaldate = raw "INTERNALDATE"
  let rfc822_header = raw "RFC822.HEADER"
  let rfc822_size = raw "RFC822.SIZE"
  let rfc822 = raw "RFC822"
  let body = raw "BODY"
  let body_section ?(peek = true) ?section:(sec = [], None) () =
    raw (if peek then "BODY.PEEK" else "BODY") & raw "[" & MIME.Request.encode sec & raw "]"
  let bodystructure = raw "BODYSTRUCTURE"
  let uid = raw "UID"
  let flags = raw "FLAGS"

  let all = [flags; internaldate; rfc822_size; envelope]
  let fast = [flags; internaldate; rfc822_size]
  let full = [flags; internaldate; rfc822_size; envelope; body]

  let x_gm_msgid = raw "X-GM-MSGID"
  let x_gm_thrid = raw "X-GM-THRID"
  let x_gm_labels = raw "X-GM-LABELS"
end

module Response = struct
  type t =
    {
      seq: seq;
      flags: Flag.t list;
      envelope: Envelope.t option;
      internaldate: string;
      rfc822_header: string;
      rfc822_text: string;
      rfc822_size: int option;
      rfc822: string;
      body: MIME.Response.t option;
      bodystructure: MIME.Response.t option;
      body_section: (MIME.Section.t * string) list;
      uid: uid;
      modseq: modseq;
      x_gm_msgid: modseq;
      x_gm_thrid: modseq;
      x_gm_labels: string list;
    } [@@deriving sexp]

  let default =
    {
      seq = 0l;
      flags = [];
      envelope = None;
      internaldate = "";
      rfc822_header = "";
      rfc822_text = "";
      rfc822_size = None;
      rfc822 = "";
      body = None;
      bodystructure = None;
      body_section = [];
      uid = 0l;
      modseq = 0L;
      x_gm_msgid = 0L;
      x_gm_thrid = 0L;
      x_gm_labels = [];
    }
end
