// $Source: /Users/x/Dropbox/2/src/blog/2025/09/23/RCS/mothra6.js,v $
// $Date: 2025/09/24 05:47:56 $
// $Revision: 1.2 $

// Playing around with 31 EDO Mothra 6
// As described in https://www.youtube.com/watch?v=uH3ahBzDSrs
// by Zheanna Erose

// Paste this code into https://strudel.cc/

stack(
  // Main melody
  freq(sequence(0, 6, 18, 12, 30, 24, 18, 6)
    .fmap(step => 220 * Math.pow(2, step/31))
    .slow(2))
    .s('sine').gain(0.4)._punchcard().color("red"),
  
  // Counter-melody in different rhythm
  freq(sequence(12, 30, 6, 24, 0, 18)
    .fmap(step => 440 * Math.pow(2, step/31))
    .slow(3))
    .s('triangle').gain(0.3).lpf(1000)._punchcard().color("cyan"),
  
  // Bass line using octave displacement
  freq(sequence(0, 6, 12, 18)
    .fmap(step => 110 * Math.pow(2, step/31))
    .slow(4))
    .s('sawtooth').lpf(400).gain(0.5)._punchcard().color("orange")
)

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
