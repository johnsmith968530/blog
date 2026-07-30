#!/usr/bin/env bun

/**
 * mill-town-decay.ts
 * A toy model of deindustrialization and systemic incarceration.
 */

enum Status {
  EMPLOYED = "Employed",
  UNEMPLOYED = "Unemployed",
  INCARCERATED = "Incarcerated",
  RELEASED_WITH_RECORD = "Justice-Involved",
}

interface Citizen {
  id: number;
  status: Status;
  hasRecord: boolean;
}

// --- Configuration ---
const POPULATION_SIZE = 1000;
const YEARS = 40;
const INITIAL_UNEMPLOYMENT = 0.05; // 5% starting unemployment
const JOB_LOSS_PER_YEAR = 0.04;    // 4% of total jobs vanish annually
const BASE_CRIME_IMPULSE = 0.02;   // Probability an unemployed person "gets in trouble"

let totalJobs = Math.floor(POPULATION_SIZE * (1 - INITIAL_UNEMPLOYMENT));
let population: Citizen[] = Array.from({ length: POPULATION_SIZE }, (_, i) => ({
  id: i,
  status: i < totalJobs ? Status.EMPLOYED : Status.UNEMPLOYED,
  hasRecord: false,
}));

console.log(`Year | Jobs | Unemp% | Incarcerated | Damaged Nodes (Record)`);
console.log(`-----------------------------------------------------------`);

for (let year = 1; year <= YEARS; year++) {
  // 1. Globalization hits: Jobs decline
  totalJobs = Math.max(0, Math.floor(totalJobs * (1 - JOB_LOSS_PER_YEAR)));

  // 2. State Transitions
  population.forEach(person => {
    const roll = Math.random();

    switch (person.status) {
      case Status.EMPLOYED:
        // If jobs vanished, some employed people become unemployed
        const currentEmployed = population.filter(p => p.status === Status.EMPLOYED).length;
        if (currentEmployed > totalJobs) {
          person.status = Status.UNEMPLOYED;
        }
        break;

      case Status.UNEMPLOYED:
        // Attempt to find a job if any are open
        const filled = population.filter(p => p.status === Status.EMPLOYED).length;
        if (filled < totalJobs) {
          // "Damaged" nodes have a 90% penalty to hiring
          const hireChance = person.hasRecord ? 0.1 : 0.8;
          if (Math.random() < hireChance) {
            person.status = Status.EMPLOYED;
            break;
          }
        }

        // Desperation/Crime roll
        // Probability increases as total unemployment increases (social disorganization)
        const unempRate = population.filter(p => p.status === Status.UNEMPLOYED).length / POPULATION_SIZE;
        if (roll < (BASE_CRIME_IMPULSE + unempRate * 0.2)) {
          person.status = Status.INCARCERATED;
          person.hasRecord = true;
        }
        break;

      case Status.INCARCERATED:
        // Sentencing: 30% chance of release each year
        if (roll < 0.3) {
          person.status = Status.RELEASED_WITH_RECORD;
        }
        break;

      case Status.RELEASED_WITH_RECORD:
        // Effectively unemployed, but with the "Damaged" stigma
        person.status = Status.UNEMPLOYED;
        break;
    }
  });

  // 3. Reporting
  const unempCount = population.filter(p => p.status === Status.UNEMPLOYED).length;
  const inPrison = population.filter(p => p.status === Status.INCARCERATED).length;
  const damaged = population.filter(p => p.hasRecord).length;

  console.log(
    `${year.toString().padEnd(4)} | ` +
    `${totalJobs.toString().padEnd(4)} | ` +
    `${((unempCount / POPULATION_SIZE) * 100).toFixed(1)}%`.padEnd(6) + " | " +
    `${inPrison.toString().padEnd(12)} | ` +
    `${((damaged / POPULATION_SIZE) * 100).toFixed(1)}%`
  );
}

console.log(`\nFinal Analysis: After ${YEARS} years, ${((population.filter(p => p.hasRecord).length / POPULATION_SIZE) * 100).toFixed(1)}% of the male population is "marked."`);
