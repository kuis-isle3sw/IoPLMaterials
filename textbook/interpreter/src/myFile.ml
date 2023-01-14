let read_whole filename =
  let ch = open_in filename in
  let str = really_input_string ch (in_channel_length ch) in
  close_in ch;
  str
