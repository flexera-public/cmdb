1) Move array validation stuff (same type, etc) out of File source so Consul
   can use it. Or decide to ditch this constraint ... hmm ...
   
2) Create a Shell.new helper to enable embedding of shells into other apps

3) Extract padding/truncation/excerpting code into Text module; deal with
   corner cases better.

4) Move CMDB separator logic (join/split) into toplevel methods of CMDB;
   DRY out Shell#expand_path