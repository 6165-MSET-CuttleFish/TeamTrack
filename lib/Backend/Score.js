class EndgameScore {
    constructor(wobbleGoalsInDrop = 0, wobbleGoalsInStart = 0, pwrShots = 0, ringsOnWobble = 0){
        this.wobbleGoalsInDrop = wobbleGoalsInDrop;
        this.wobbleGoalsInStart = wobbleGoalsInStart;
        this.pwrShots =pwrShots;
        this.ringsOnWobble = ringsOnWobble;
  }
    total() {
        return this.wobbleGoalsInDrop * 20 +
          this.wobbleGoalsInStart * 5 +
          this.ringsOnWobble * 5 +
          this.pwrShots * 15;
    } 
  }