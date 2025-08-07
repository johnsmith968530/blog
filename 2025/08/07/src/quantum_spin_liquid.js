// $Source: /Users/x/Dropbox/2/src/blog/2025/08/07/src/RCS/quantum_spin_liquid.js,v $
// $Date: 2025/08/07 19:46:31 $
// $Revision: 1.1 $

// quantum_spin_liquid.js
// Node.js simulation of a small frustrated spin system
// using Monte Carlo (classical approximation)

const L = 4; // lattice size (LxL)
const N = L * L;
const beta = 1.0; // inverse temperature
const steps = 10000;
const J = []; // interactions

// Initialize spins randomly to +1 / -1
let spins = Array(N)
    .fill(0)
    .map(() => (Math.random() < 0.5 ? 1 : -1));

// Helper: 2D index to 1D
function idx(x, y) {
    return ((x + L) % L) * L + ((y + L) % L);
}

// Initialize random ±1 couplings to introduce frustration
for (let i = 0; i < N; i++) {
    J[i] = {};
    let x = Math.floor(i / L);
    let y = i % L;

    // nearest neighbors (periodic boundaries)
    const neighbors = [
        [(x + 1) % L, y],
        [(x - 1 + L) % L, y],
        [x, (y + 1) % L],
        [x, (y - 1 + L) % L],
    ];

    for (let [nx, ny] of neighbors) {
        let jIndex = idx(nx, ny);
        // Avoid double counting
        if (J[i][jIndex] === undefined) {
            J[i][jIndex] = Math.random() < 0.5 ? 1 : -1; // random sign
        }
    }
}

// Compute energy for the whole system
function totalEnergy() {
    let E = 0;
    for (let i = 0; i < N; i++) {
        for (let j in J[i]) {
            j = parseInt(j);
            E += -J[i][j] * spins[i] * spins[j];
        }
    }
    return E / 2; // double counted pairs
}

// Perform a Metropolis update
function metropolisStep() {
    const site = Math.floor(Math.random() * N);
    let dE = 0;

    for (let j in J[site]) {
        j = parseInt(j);
        dE += 2 * J[site][j] * spins[site] * spins[j];
    }

    if (dE <= 0 || Math.random() < Math.exp(-beta * dE)) {
        spins[site] *= -1; // flip spin
    }
}

// Run the simulation
console.log("Initial Energy:", totalEnergy());

for (let step = 0; step < steps; step++) {
    metropolisStep();
    if (step % 1000 === 0) {
        console.log(`Step ${step}, Energy: ${totalEnergy()}`);
    }
}

// Compute spin-spin correlation (average S_i S_j for distance=1)
function correlation() {
    let sum = 0;
    let count = 0;
    for (let i = 0; i < N; i++) {
        let x = Math.floor(i / L);
        let y = i % L;
        const neighbors = [
            [(x + 1) % L, y],
            [x, (y + 1) % L],
        ];
        for (let [nx, ny] of neighbors) {
            let j = idx(nx, ny);
            sum += spins[i] * spins[j];
            count++;
        }
    }
    return sum / count;
}

console.log("Final Energy:", totalEnergy());
console.log("Nearest-neighbor correlation:", correlation().toFixed(3));
console.log("Final spin configuration:\n");
for (let x = 0; x < L; x++) {
    console.log(spins.slice(x * L, (x + 1) * L).map(s => (s > 0 ? "↑" : "↓")).join(" "));
}

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
