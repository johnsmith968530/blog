// $Source: /Users/x/Dropbox/2/src/blog/2025/08/07/src/RCS/ollama_qwen3-coder_30b_quantum_spin_liquid.js,v $
// $Date: 2025/08/07 20:14:53 $
// $Revision: 1.3 $

// quantum-spin-liquid.js
const fs = require('fs');

class QuantumSpinLiquid {
    constructor(size, temperature = 1.0, coupling = 1.0) {
        this.size = size;
        this.temperature = temperature;
        this.coupling = coupling;
        
        // Initialize spins (random values between -1 and 1)
        this.spins = Array(size).fill().map(() => 
            Array(size).fill().map(() => Math.random() * 2 - 1)
        );
        
        // For visualization, we'll track magnetization over time
        this.magnetizationHistory = [];
    }
    
    // Calculate energy of the system
    calculateEnergy() {
        let energy = 0;
        
        for (let i = 0; i < this.size; i++) {
            for (let j = 0; j < this.size; j++) {
                const spin = this.spins[i][j];
                
                // Nearest neighbors (periodic boundary conditions)
                const neighbors = [
                    this.spins[(i + 1) % this.size][j],
                    this.spins[i][(j + 1) % this.size],
                    this.spins[(i - 1 + this.size) % this.size][j],
                    this.spins[i][(j - 1 + this.size) % this.size]
                ];
                
                // Energy contribution from each neighbor
                for (const neighbor of neighbors) {
                    energy -= this.coupling * spin * neighbor;
                }
            }
        }
        
        return energy / 2; // Avoid double counting
    }
    
    // Calculate magnetization (average of all spins)
    calculateMagnetization() {
        let total = 0;
        for (let i = 0; i < this.size; i++) {
            for (let j = 0; j < this.size; j++) {
                total += this.spins[i][j];
            }
        }
        return Math.abs(total / (this.size * this.size));
    }
    
    // Monte Carlo step with Metropolis algorithm
    monteCarloStep() {
        for (let i = 0; i < this.size * this.size; i++) {
            // Random site selection
            const x = Math.floor(Math.random() * this.size);
            const y = Math.floor(Math.random() * this.size);
            
            // Flip spin
            const oldSpin = this.spins[x][y];
            this.spins[x][y] = -oldSpin;
            
            // Calculate energy difference
            const deltaE = this.calculateEnergyDifference(x, y);
            
            // Accept or reject based on Boltzmann probability
            if (deltaE > 0 && Math.random() > Math.exp(-deltaE / this.temperature)) {
                // Reject the flip
                this.spins[x][y] = oldSpin;
            }
        }
    }
    
    // Calculate energy difference for a specific spin flip
    calculateEnergyDifference(x, y) {
        const spin = this.spins[x][y];
        let deltaE = 0;
        
        // Nearest neighbors (periodic boundary conditions)
        const neighbors = [
            this.spins[(x + 1) % this.size][y],
            this.spins[x][(y + 1) % this.size],
            this.spins[(x - 1 + this.size) % this.size][y],
            this.spins[x][(y - 1 + this.size) % this.size]
        ];
        
        // Energy difference due to the flip
        for (const neighbor of neighbors) {
            deltaE += 2 * this.coupling * spin * neighbor;
        }
        
        return deltaE;
    }
    
    // Run simulation for a number of steps
    run(steps = 1000) {
        console.log(`Starting quantum spin liquid simulation with ${steps} steps`);
        console.log(`System size: ${this.size}x${this.size}`);
        console.log(`Temperature: ${this.temperature}`);
        console.log(`Coupling strength: ${this.coupling}`);
        console.log('---');
        
        for (let step = 0; step < steps; step++) {
            this.monteCarloStep();
            
            // Record magnetization every 100 steps
            if (step % 100 === 0) {
                const magnetization = this.calculateMagnetization();
                this.magnetizationHistory.push({
                    step,
                    magnetization,
                    energy: this.calculateEnergy()
                });
                
                if (step % 500 === 0) {
                    console.log(`Step ${step}: Magnetization = ${magnetization.toFixed(4)}, Energy = ${this.calculateEnergy().toFixed(2)}`);
                }
            }
        }
        
        const finalMagnetization = this.calculateMagnetization();
        console.log(`---`);
        console.log(`Final magnetization: ${finalMagnetization.toFixed(4)}`);
        console.log(`Final energy: ${this.calculateEnergy().toFixed(2)}`);
    }
    
    // Export results to a file
    exportResults(filename = 'ollama_qwen3-coder_30b_quantum_spin_liquid_results.json') {
        const data = {
            parameters: {
                size: this.size,
                temperature: this.temperature,
                coupling: this.coupling
            },
            results: this.magnetizationHistory
        };
        
        fs.writeFileSync(filename, JSON.stringify(data, null, 2));
        console.log(`Results exported to ${filename}`);
    }
    
    // Print a simple visualization of the spin configuration
    printVisualization() {
        console.log('\nSpin configuration:');
        for (let i = 0; i < this.size; i++) {
            let row = '';
            for (let j = 0; j < this.size; j++) {
                const spin = this.spins[i][j];
                row += spin > 0 ? '↑' : '↓';
            }
            console.log(row);
        }
    }
}

// Main execution
function main() {
    // Create a quantum spin liquid simulation
    const size = 16; // System size (16x16 grid)
    const temperature = 0.5; // Low temperature to promote quantum fluctuations
    const coupling = 1.0; // Coupling strength
    
    console.log('Quantum Spin Liquid Simulation');
    console.log('==============================');
    
    const spinLiquid = new QuantumSpinLiquid(size, temperature, coupling);
    
    // Run the simulation
    spinLiquid.run(2000);
    
    // Print final visualization
    spinLiquid.printVisualization();
    
    // Export results
    spinLiquid.exportResults('ollama_qwen3-coder_30b_quantum_spin_liquid.json');
    
    console.log('\nSimulation completed successfully!');
}

// Run the simulation if this file is executed directly
if (require.main === module) {
    main();
}

module.exports = QuantumSpinLiquid;

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
