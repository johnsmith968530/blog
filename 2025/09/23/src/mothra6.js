// $Source: /Users/x/Dropbox/2/src/blog/2025/09/23/src/RCS/mothra6.js,v $
// $Date: 2025/09/24 06:24:15 $
// $Revision: 1.6 $

// Playing around with 31 EDO Mothra 6
// As described in https://www.youtube.com/watch?v=uH3ahBzDSrs
// by Zheanna Erose

// Paste this code into https://strudel.cc/

const getEdoFrequency = (baseFreq, edo, step) => {
  return baseFreq * Math.pow(2, step / edo);
};

// Using only 31 EDO frequencies for beat effects

stack(
  // Main melody with shimmer layer (1 step higher in 31 EDO)
  stack(
    freq(sequence(0, 6, 18, 12, 30, 24, 18, 6)
      .fmap(step => getEdoFrequency(220, 31, step))
      .slow(2))
      .s('sine').gain(0.3),
    
    // Shimmer layer - 1 step higher for beating
    freq(sequence(1, 7, 19, 13, 31, 25, 19, 7)  // +1 step from original
      .fmap(step => getEdoFrequency(220, 31, step))
      .slow(2))
      .s('sine').gain(0.2)
  )._punchcard().color("red"),
  
  // Counter-melody with warble (close interval beating)
  stack(
    freq(sequence(12, 30, 6, 24, 0, 18)
      .fmap(step => getEdoFrequency(440, 31, step))
      .slow(3))
      .s('triangle').gain(0.25).lpf(1000),
    
    // Add a note 1 step higher in 31 EDO for close interval beating
    freq(sequence(13, 31, 7, 25, 1, 19)  // +1 step from original
      .fmap(step => getEdoFrequency(440, 31, step))
      .slow(3))
      .s('triangle').gain(0.15).lpf(1000)
  )._punchcard().color("cyan"),
  
  // Bass line with beating (2 step intervals)
  stack(
    freq(sequence(0, 6, 12, 18)
      .fmap(step => getEdoFrequency(110, 31, step))
      .slow(4))
      .s('sawtooth').lpf(400).gain(0.4),
    
    // 2 steps higher for stronger beating in bass register
    freq(sequence(2, 8, 14, 20)  // +2 steps from original
      .fmap(step => getEdoFrequency(110, 31, step))
      .slow(4))
      .s('sawtooth').lpf(400).gain(0.2)
  )._punchcard().color("orange"),
  
  // New: High shimmer layer using perfect fifths (18 steps in 31 EDO ≈ 696 cents)
  freq(sequence(18, 24, 30, 36, 48, 42, 36, 24)  // +18 steps from main melody
    .fmap(step => getEdoFrequency(220, 31, step))
    .slow(2))
    .s('sine').gain(0.15).hpf(800)._punchcard().color("yellow"),
  
  // New: Tremolo effect layer for additional shimmer
  freq(sequence(6, 12, 24, 18, 36, 30, 24, 12)
    .fmap(step => getEdoFrequency(330, 31, step))
    .slow(2.5))
    .s('triangle')
    .gain(sine.range(0.05, 0.2).slow(8))  // Slow tremolo
    .lpf(1500)._punchcard().color("green")
)

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
