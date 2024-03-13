(** YAML witness format types. *)

module Producer =
struct
  type t = {
    name: string;
    version: string;
    (* TODO: configuration *)
    command_line: string option;
    (* TODO: description *)
  }
  [@@deriving eq, ord, hash]

  let to_yaml {name; version; command_line} =
    `O ([
        ("name", `String name);
        ("version", `String version);
      ] @ match command_line with
      | Some command_line -> [
          ("command_line", `String command_line);
        ]
      | None ->
        []
      )

  let of_yaml y =
    let open GobYaml in
    let+ name = y |> find "name" >>= to_string
    and+ version = y |> find "version" >>= to_string
    and+ command_line = y |> Yaml.Util.find "command_line" >>= option_map to_string in
    {name; version; command_line}
end

module Task =
struct
  type t = {
    input_files: string list;
    input_file_hashes: (string * string) list;
    data_model: string;
    language: string;
    specification: string option;
  }
  [@@deriving eq, ord, hash]

  let to_yaml {input_files; input_file_hashes; data_model; language; specification} =
    `O ([
        ("input_files", `A (List.map Yaml.Util.string input_files));
        ("input_file_hashes", `O (List.map (fun (file, hash) ->
             (file, `String hash)
           ) input_file_hashes));
        ("data_model", `String data_model);
        ("language", `String language);
      ] @ match specification with
      | Some specification -> [
          ("specification", `String specification)
        ]
      | None ->
        []
      )

  let of_yaml y =
    let open GobYaml in
    let+ input_files = y |> find "input_files" >>= list >>= list_map to_string
    and+ input_file_hashes = y |> find "input_file_hashes" >>= entries >>= list_map (fun (file, y_hash) ->
        let+ hash = to_string y_hash in
        (file, hash)
      )
    and+ data_model = y |> find "data_model" >>= to_string
    and+ language = y |> find "language" >>= to_string
    and+ specification = y |> Yaml.Util.find "specification" >>= option_map to_string in
    {input_files; input_file_hashes; data_model; language; specification}
end

module Metadata =
struct
  type t = {
    format_version: string;
    uuid: string;
    creation_time: string;
    producer: Producer.t;
    task: Task.t option;
  }
  [@@deriving eq, ord, hash]

  let to_yaml {format_version; uuid; creation_time; producer; task} =
    `O ([
        ("format_version", `String format_version);
        ("uuid", `String uuid);
        ("creation_time", `String creation_time);
        ("producer", Producer.to_yaml producer);
      ] @ match task with
      | Some task -> [
          ("task", Task.to_yaml task)
        ]
      | None ->
        []
      )
  let of_yaml y =
    let open GobYaml in
    let+ format_version = y |> find "format_version" >>= to_string
    and+ uuid = y |> find "uuid" >>= to_string
    and+ creation_time = y |> find "creation_time" >>= to_string
    and+ producer = y |> find "producer" >>= Producer.of_yaml
    and+ task = y |> Yaml.Util.find "task" >>= option_map Task.of_yaml in
    {format_version; uuid; creation_time; producer; task}
end

module Location =
struct
  type t = {
    file_name: string;
    file_hash: string;
    line: int;
    column: int;
    function_: string;
  }
  [@@deriving eq, ord, hash]

  let to_yaml {file_name; file_hash; line; column; function_} =
    `O [
      ("file_name", `String file_name);
      ("file_hash", `String file_hash);
      ("line", `Float (float_of_int line));
      ("column", `Float (float_of_int column));
      ("function", `String function_);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ file_name = y |> find "file_name" >>= to_string
    and+ file_hash = y |> find "file_hash" >>= to_string
    and+ line = y |> find "line" >>= to_int
    and+ column = y |> find "column" >>= to_int
    and+ function_ = y |> find "function" >>= to_string in
    {file_name; file_hash; line; column; function_}
end

module Invariant =
struct
  type t = {
    string: string;
    type_: string;
    format: string;
  }
  [@@deriving eq, ord, hash]

  let to_yaml {string; type_; format} =
    `O [
      ("string", `String string);
      ("type", `String type_);
      ("format", `String format);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ string = y |> find "string" >>= to_string
    and+ type_ = y |> find "type" >>= to_string
    and+ format = y |> find "format" >>= to_string in
    {string; type_; format}
end

module LoopInvariant =
struct
  type t = {
    location: Location.t;
    loop_invariant: Invariant.t;
  }
  [@@deriving eq, ord, hash]

  let entry_type = "loop_invariant"

  let to_yaml' {location; loop_invariant} =
    [
      ("location", Location.to_yaml location);
      ("loop_invariant", Invariant.to_yaml loop_invariant);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ location = y |> find "location" >>= Location.of_yaml
    and+ loop_invariant = y |> find "loop_invariant" >>= Invariant.of_yaml in
    {location; loop_invariant}
end

module LocationInvariant =
struct
  type t = {
    location: Location.t;
    location_invariant: Invariant.t;
  }
  [@@deriving eq, ord, hash]

  let entry_type = "location_invariant"

  let to_yaml' {location; location_invariant} =
    [
      ("location", Location.to_yaml location);
      ("location_invariant", Invariant.to_yaml location_invariant);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ location = y |> find "location" >>= Location.of_yaml
    and+ location_invariant = y |> find "location_invariant" >>= Invariant.of_yaml in
    {location; location_invariant}
end

module FlowInsensitiveInvariant =
struct
  type t = {
    flow_insensitive_invariant: Invariant.t;
  }
  [@@deriving eq, ord, hash]

  let entry_type = "flow_insensitive_invariant"

  let to_yaml' {flow_insensitive_invariant} =
    [
      ("flow_insensitive_invariant", Invariant.to_yaml flow_insensitive_invariant);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ flow_insensitive_invariant = y |> find "flow_insensitive_invariant" >>= Invariant.of_yaml in
    {flow_insensitive_invariant}
end

module PreconditionLoopInvariant =
struct
  type t = {
    location: Location.t;
    loop_invariant: Invariant.t;
    precondition: Invariant.t;
  }
  [@@deriving eq, ord, hash]

  let entry_type = "precondition_loop_invariant"

  let to_yaml' {location; loop_invariant; precondition} =
    [
      ("location", Location.to_yaml location);
      ("loop_invariant", Invariant.to_yaml loop_invariant);
      ("precondition", Invariant.to_yaml precondition);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ location = y |> find "location" >>= Location.of_yaml
    and+ loop_invariant = y |> find "loop_invariant" >>= Invariant.of_yaml
    and+ precondition = y |> find "precondition" >>= Invariant.of_yaml in
    {location; loop_invariant; precondition}
end

module InvariantSet =
struct
  module LoopInvariant =
  struct
    type t = {
      location: Location.t;
      value: string;
      format: string;
    }
    [@@deriving eq, ord, hash]

    let invariant_type = "loop_invariant"

    let to_yaml' {location; value; format} =
      [
        ("location", Location.to_yaml location);
        ("value", `String value);
        ("format", `String format);
      ]

    let of_yaml y =
      let open GobYaml in
      let+ location = y |> find "location" >>= Location.of_yaml
      and+ value = y |> find "value" >>= to_string
      and+ format = y |> find "format" >>= to_string in
      {location; value; format}
  end

  module LocationInvariant =
  struct
    include LoopInvariant

    let invariant_type = "location_invariant"
  end

  (* TODO: could maybe use GADT, but adds ugly existential layer to entry type pattern matching *)
  module InvariantType =
  struct
    type t =
      | LocationInvariant of LocationInvariant.t
      | LoopInvariant of LoopInvariant.t
    [@@deriving eq, ord, hash]

    let invariant_type = function
      | LocationInvariant _ -> LocationInvariant.invariant_type
      | LoopInvariant _ -> LoopInvariant.invariant_type

    let to_yaml' = function
      | LocationInvariant x -> LocationInvariant.to_yaml' x
      | LoopInvariant x -> LoopInvariant.to_yaml' x

    let of_yaml y =
      let open GobYaml in
      let* invariant_type = y |> find "type" >>= to_string in
      if invariant_type = LocationInvariant.invariant_type then
        let+ x = y |> LocationInvariant.of_yaml in
        LocationInvariant x
      else if invariant_type = LoopInvariant.invariant_type then
        let+ x = y |> LoopInvariant.of_yaml in
        LoopInvariant x
      else
        Error (`Msg "type")
  end

  module Invariant =
  struct
    type t = {
      invariant_type: InvariantType.t;
    }
    [@@deriving eq, ord, hash]

    let to_yaml {invariant_type} =
      `O [
        ("invariant", `O ([
             ("type", `String (InvariantType.invariant_type invariant_type));
           ] @ InvariantType.to_yaml' invariant_type)
        )
      ]

    let of_yaml y =
      let open GobYaml in
      let+ invariant_type = y |> find "invariant" >>= InvariantType.of_yaml in
      {invariant_type}
  end

  type t = {
    content: Invariant.t list;
  }
  [@@deriving eq, ord, hash]

  let entry_type = "invariant_set"

  let to_yaml' {content} =
    [("content", `A (List.map Invariant.to_yaml content))]

  let of_yaml y =
    let open GobYaml in
    let+ content = y |> find "content" >>= list >>= list_map Invariant.of_yaml in
    {content}
end

module Target =
struct
  type t = {
    uuid: string;
    type_: string;
    file_hash: string;
  }
  [@@deriving eq, ord, hash]

  let to_yaml {uuid; type_; file_hash} =
    `O [
      ("uuid", `String uuid);
      ("type", `String type_);
      ("file_hash", `String file_hash);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ uuid = y |> find "uuid" >>= to_string
    and+ type_ = y |> find "type" >>= to_string
    and+ file_hash = y |> find "file_hash" >>= to_string in
    {uuid; type_; file_hash}
end

module Certification =
struct
  type t = {
    string: string;
    type_: string;
    format: string;
  }
  [@@deriving eq, ord, hash]

  let to_yaml {string; type_; format} =
    `O [
      ("string", `String string);
      ("type", `String type_);
      ("format", `String format);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ string = y |> find "string" >>= to_string
    and+ type_ = y |> find "type" >>= to_string
    and+ format = y |> find "format" >>= to_string in
    {string; type_; format}
end

module LoopInvariantCertificate =
struct
  type t = {
    target: Target.t;
    certification: Certification.t;
  }
  [@@deriving eq, ord, hash]

  let entry_type = "loop_invariant_certificate"

  let to_yaml' {target; certification} =
    [
      ("target", Target.to_yaml target);
      ("certification", Certification.to_yaml certification);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ target = y |> find "target" >>= Target.of_yaml
    and+ certification = y |> find "certification" >>= Certification.of_yaml in
    {target; certification}
end

module PreconditionLoopInvariantCertificate =
struct
  include LoopInvariantCertificate
  let entry_type = "precondition_loop_invariant_certificate"
end

module GhostVariable =
struct
  type t = {
    variable: string;
    scope: string;
    type_: string;
    initial: string;
  }
  [@@deriving eq, ord, hash]

  let entry_type = "ghost_variable"

  let to_yaml' {variable; scope; type_; initial} =
    [
      ("variable", `String variable);
      ("scope", `String scope);
      ("type", `String type_);
      ("initial", `String initial);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ variable = y |> find "variable" >>= to_string
    and+ scope = y |> find "scope" >>= to_string
    and+ type_ = y |> find "type" >>= to_string
    and+ initial = y |> find "initial" >>= to_string in
    {variable; scope; type_; initial}
end

module GhostUpdate =
struct
  type t = {
    variable: string;
    expression: string;
    location: Location.t;
    (* TODO: branching? *)
  }
  [@@deriving eq, ord, hash]

  let entry_type = "ghost_update"

  let to_yaml' {variable; expression; location} =
    [
      ("variable", `String variable);
      ("expression", `String expression);
      ("location", Location.to_yaml location);
    ]

  let of_yaml y =
    let open GobYaml in
    let+ variable = y |> find "variable" >>= to_string
    and+ expression = y |> find "expression" >>= to_string
    and+ location = y |> find "location" >>= Location.of_yaml in
    {variable; expression; location}
end

(* TODO: could maybe use GADT, but adds ugly existential layer to entry type pattern matching *)
module EntryType =
struct
  type t =
    | LocationInvariant of LocationInvariant.t
    | LoopInvariant of LoopInvariant.t
    | FlowInsensitiveInvariant of FlowInsensitiveInvariant.t
    | PreconditionLoopInvariant of PreconditionLoopInvariant.t
    | LoopInvariantCertificate of LoopInvariantCertificate.t
    | PreconditionLoopInvariantCertificate of PreconditionLoopInvariantCertificate.t
    | InvariantSet of InvariantSet.t
    | GhostVariable of GhostVariable.t
    | GhostUpdate of GhostUpdate.t
  [@@deriving eq, ord, hash]

  let entry_type = function
    | LocationInvariant _ -> LocationInvariant.entry_type
    | LoopInvariant _ -> LoopInvariant.entry_type
    | FlowInsensitiveInvariant _ -> FlowInsensitiveInvariant.entry_type
    | PreconditionLoopInvariant _ -> PreconditionLoopInvariant.entry_type
    | LoopInvariantCertificate _ -> LoopInvariantCertificate.entry_type
    | PreconditionLoopInvariantCertificate _ -> PreconditionLoopInvariantCertificate.entry_type
    | InvariantSet _ -> InvariantSet.entry_type
    | GhostVariable _ -> GhostVariable.entry_type
    | GhostUpdate _ -> GhostUpdate.entry_type

  let to_yaml' = function
    | LocationInvariant x -> LocationInvariant.to_yaml' x
    | LoopInvariant x -> LoopInvariant.to_yaml' x
    | FlowInsensitiveInvariant x -> FlowInsensitiveInvariant.to_yaml' x
    | PreconditionLoopInvariant x -> PreconditionLoopInvariant.to_yaml' x
    | LoopInvariantCertificate x -> LoopInvariantCertificate.to_yaml' x
    | PreconditionLoopInvariantCertificate x -> PreconditionLoopInvariantCertificate.to_yaml' x
    | InvariantSet x -> InvariantSet.to_yaml' x
    | GhostVariable x -> GhostVariable.to_yaml' x
    | GhostUpdate x -> GhostUpdate.to_yaml' x

  let of_yaml y =
    let open GobYaml in
    let* entry_type = y |> find "entry_type" >>= to_string in
    if entry_type = LocationInvariant.entry_type then
      let+ x = y |> LocationInvariant.of_yaml in
      LocationInvariant x
    else if entry_type = LoopInvariant.entry_type then
      let+ x = y |> LoopInvariant.of_yaml in
      LoopInvariant x
    else if entry_type = FlowInsensitiveInvariant.entry_type then
      let+ x = y |> FlowInsensitiveInvariant.of_yaml in
      FlowInsensitiveInvariant x
    else if entry_type = PreconditionLoopInvariant.entry_type then
      let+ x = y |> PreconditionLoopInvariant.of_yaml in
      PreconditionLoopInvariant x
    else if entry_type = LoopInvariantCertificate.entry_type then
      let+ x = y |> LoopInvariantCertificate.of_yaml in
      LoopInvariantCertificate x
    else if entry_type = PreconditionLoopInvariantCertificate.entry_type then
      let+ x = y |> PreconditionLoopInvariantCertificate.of_yaml in
      PreconditionLoopInvariantCertificate x
    else if entry_type = InvariantSet.entry_type then
      let+ x = y |> InvariantSet.of_yaml in
      InvariantSet x
    else if entry_type = GhostVariable.entry_type then
      let+ x = y |> GhostVariable.of_yaml in
      GhostVariable x
    else if entry_type = GhostUpdate.entry_type then
      let+ x = y |> GhostUpdate.of_yaml in
      GhostUpdate x
    else
      Error (`Msg ("entry_type " ^ entry_type))
end

module Entry =
struct
  include Printable.StdLeaf

  type t = {
    entry_type: EntryType.t;
    metadata: Metadata.t [@equal fun _ _ -> true] [@compare fun _ _ -> 0] [@hash fun _ -> 1];
  }
  [@@deriving eq, ord, hash]

  let name () = "YAML entry"

  let show _ = "TODO"
  include Printable.SimpleShow (struct
      type nonrec t = t
      let show = show
    end)

  let to_yaml {entry_type; metadata} =
    `O ([
        ("entry_type", `String (EntryType.entry_type entry_type));
        ("metadata", Metadata.to_yaml metadata);
      ] @ EntryType.to_yaml' entry_type)

  let of_yaml y =
    let open GobYaml in
    let+ metadata = y |> find "metadata" >>= Metadata.of_yaml
    and+ entry_type = y |> EntryType.of_yaml in
    {entry_type; metadata}
end
