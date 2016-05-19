require_relative "ruby_lib/graphs"

RPlotter.new("Experiment 2b", 
             "#Pagefaults", 
             "output/test2b/events.log", 
             { 
              "a" => "output/test2b/a.log", 
              "b" => "output/test2b/b.log",
              "c" => "output/test2b/c.log",
              "c2" => "output/test2b/c2.log",
             },
).plot!("output-2b.svg")
