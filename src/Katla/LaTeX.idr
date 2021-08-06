||| Functions for generating
module Katla.LaTeX

import Core.Metadata
import System.File

import Collie
import Katla.Config

export
escapeLatex : Char -> List Char
escapeLatex '\\' = fastUnpack "\\textbackslash{}"
escapeLatex '{'  = fastUnpack "\\{"
escapeLatex '}'  = fastUnpack "\\}"
escapeLatex x    = [x]

export
annotate : Maybe Decoration -> String -> String
annotate Nothing    s = s
annotate (Just dec) s = apply (convert dec) s
  where
    convert : Decoration -> String
    convert (Typ     ) = "IdrisType"
    convert (Function) = "IdrisFunction"
    convert (Data    ) = "IdrisData"
    convert (Keyword ) = "IdrisKeyword"
    convert (Bound   ) = "IdrisBound"

    apply : String -> String -> String
    apply f a = "\\\{f}{\{a}}"

export
color : String -> String
color x = "\\color{\{x}}"

export
laTeXHeader : Config -> String
laTeXHeader cfg =  """
\\newcommand{\\IdrisHlightFont}         {\{cfg.font}}
\\newcommand{\\IdrisHlightStyleData}    {\{cfg.datacons.style}}
\\newcommand{\\IdrisHlightStyleType}    {\{cfg.typecons.style}}
\\newcommand{\\IdrisHlightStyleBound}   {\{cfg.bound   .style}}
\\newcommand{\\IdrisHlightStyleFunction}{\{cfg.function.style}}
\\newcommand{\\IdrisHlightStyleKeyword} {\{cfg.keyword .style}}
\\newcommand{\\IdrisHlightStyleImplicit}{\{cfg.bound   .style}}
\\newcommand{\\IdrisHlightStyleComment} {\{cfg.comment .style}}
\\newcommand{\\IdrisHlightStyleHole}    {\{cfg.hole    .style}}

\\newcommand{\\IdrisHlightColourData}    {\{cfg.datacons.colour}}
\\newcommand{\\IdrisHlightColourType}    {\{cfg.typecons.colour}}
\\newcommand{\\IdrisHlightColourBound}   {\{cfg.bound   .colour}}
\\newcommand{\\IdrisHlightColourFunction}{\{cfg.function.colour}}
\\newcommand{\\IdrisHlightColourKeyword} {\{cfg.keyword .colour}}
\\newcommand{\\IdrisHlightColourImplicit}{\{cfg.bound   .colour}}
\\newcommand{\\IdrisHlightColourComment} {\{cfg.comment .colour}}
\\newcommand{\\IdrisHlightColourHole}    {\{cfg.hole    .colour}}

\\newcommand{\\IdrisHole}[1]{{%
    \\colorbox{yellow}{%
      \\IdrisHlightStyleHole\\IdrisHlightFont%
      #1}}}

\\newcommand{\\RawIdrisHighlight}[3]{{\\textcolor{#1}{#2\\IdrisHlightFont#3}}}

\\newcommand{\\IdrisData}[1]{\\RawIdrisHighlight{\\IdrisHlightColourData}{\\IdrisHlightStyleData}{#1}}
\\newcommand{\\IdrisType}[1]{\\RawIdrisHighlight{\\IdrisHlightColourType}{\\IdrisHlightStyleType}{#1}}
\\newcommand{\\IdrisBound}[1]{\\RawIdrisHighlight{\\IdrisHlightColourBound}{\\IdrisHlightStyleBound}{#1}}
\\newcommand{\\IdrisFunction}[1]{\\RawIdrisHighlight{\\IdrisHlightColourFunction}{\\IdrisHlightStyleFunction}{#1}}
\\newcommand{\\IdrisKeyword}[1]{\\RawIdrisHighlight{\\IdrisHlightColourKeyword}{\\IdrisHlightStyleKeyword}{#1}}
\\newcommand{\\IdrisImplicit}[1]{\\RawIdrisHighlight{\\IdrisHlightColourImplicit}{\\IdrisHlightStyleImplicit}{#1}}
\\newcommand{\\IdrisComment}[1]{\\RawIdrisHighlight{\\IdrisHlightColourComment}{\\IdrisHlightStyleComment}{#1}}
"""


export
standalonePre : Config -> String
standalonePre config = """
  \\documentclass{article}

  \\usepackage{fancyvrb}
  \\usepackage[x11names]{xcolor}

  \{laTeXHeader config}

  \\begin{document}
  %\\VerbatimInput[commandchars=\\\\\\{\\}]{content}
  \\begin{Verbatim}[commandchars=\\\\\\{\\}]
  """

export
standalonePost : String
standalonePost = """
  \\end{Verbatim}
  \\end{document}
  """

export
makeMacroPre : String -> String
makeMacroPre name = """
  \\newcommand\\\{name}{\\UseVerbatim{\{name}}}
  \\begin{SaveVerbatim}[commandchars=\\\\\\{\\}]{\{name}}
  """

export
makeMacroPost : String
makeMacroPost = """
  \\end{SaveVerbatim}
  """




public export
preambleCmd : Command "preamble"
preambleCmd = MkCommand
  { description = "Generate LaTeX preamble"
  , subcommands = []
  , modifiers =
    [ "--config" ::= option """
        Preamble configuration file in Dhall format.
        Use `init` to generate the defaults config file.
        """
        filePath
    ]
  , arguments = filePath
  }

public export
initCmd : Command "init"
initCmd = MkCommand
  { description = "Generate preamble configuration file"
  , subcommands = []
  , modifiers = []
  , arguments = filePath
  }



preambleExec : (moutput : Maybe String) -> (configFile : Maybe String) -> IO ()
preambleExec moutput configFile = do
  Right file <- maybe (pure $ Right stdout) (flip openFile WriteTruncate) moutput
  | Left err => putStrLn """
              Error while opening preamble file \{maybe "stdout" id moutput}:
              \{show err}
              """
  config <- getConfiguration configFile
  Right () <- fPutStr file $ laTeXHeader config
  | Left err => putStrLn """
      Error while writing preamble file \{maybe "stdout" id moutput}:
      \{show err}
      """
  closeFile file

export
preamble : (ParsedCommand Prelude.id Maybe _ LaTeX.preambleCmd) -> IO ()
preamble parsed = preambleExec parsed.arguments (parsed.modifiers.project "--config")

export
initExec : (moutput : Maybe String) -> IO ()
initExec moutput = do
  Right file <- maybe (pure $ Right stdout) (flip openFile WriteTruncate) moutput
  | Left err => putStrLn """
              Error while opening configuration file \{maybe "stdout" id moutput}:
              \{show err}
              """
  Right () <- fPutStrLn file $ defaultConfig.toString
  | Left err => putStrLn """
      Error while writing preamble file \{maybe "stdout" id moutput}:
      \{show err}
      """
  closeFile file

export
init : (ParsedCommand Prelude.id Maybe _ LaTeX.initCmd) -> IO ()
init parsed = initExec parsed.arguments
