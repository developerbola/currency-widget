export const command = "./Currency.widget/rates.sh";
export const refreshFrequency = 60 * 1000 * 60 * 24;
let pairs = [];
let todays = {};

export const render = ({ output }) => {
  // Check if data is available
  if (!output) {
    return (
      <div className="wrapper">
        <div className="rate rate-wrapper loading-container">
          <div className="spinner">
            <div className="spinner-circle"></div>
          </div>
        </div>
      </div>
    );
  }

  pairs = output.split("!!");
  const rateData = pairs.map((pair) => {
    const [date, rate, diff] = pair.split(":");
    return { date, rate: parseFloat(rate), diff };
  });

  todays = rateData[0] || { date: "", rate: 0, diff: "0" };

  // Calculate the average rate from all data points
  const calculateAverage = () => {
    if (rateData.length === 0) return "0";
    const sum = rateData.reduce((acc, item) => acc + item.rate, 0);
    const avg = sum / rateData.length;
    return formatRate(avg.toFixed(3)).slice(0, 5);
  };

  const todaysRate = () => {
    return formatRate(todays.rate);
  };

  // Utils
  const formatRate = (rate) => {
    const cleanNumber = Math.round(rate * 100).toString();
    const formatted = cleanNumber.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    return formatted;
  };

  const diffColor = (differency) => {
    if (!differency) return "#4ade80";
    const sym = differency.split("")[0];
    if (sym === "-") {
      return "#f87171";
    }
    return "#4ade80";
  };

  const blockY = (diff) => {
    if (!diff) return "0";
    const charArr = diff.split("");
    if (charArr[0] === "-") {
      return charArr.slice(1, charArr.length).join("");
    }
    return "-" + diff;
  };

  return (
    <div className="wrapper">
      <div className="rate rate-wrapper">
        <p className="diff" style={{ opacity: 0.6 }}>
          USD-UZS - {todays.date.split("-")[2]}.{todays.date.split("-")[1]}
        </p>
        <p>{todaysRate()} UZS</p>
        <div style={{ display: "flex", gap: "7px" }}>
          <p className="diff" style={{ opacity: 0.6 }}>
            avg: {calculateAverage()}
          </p>
          <p style={{ color: diffColor(todays.diff) }} className="diff">
            {todays.diff}%
          </p>
        </div>
      </div>
      <div className="rate rate-chart">
        {rateData
          .slice()
          .reverse()
          .map((item, i) => {
            return (
              <div
                className="rate-block"
                style={{
                  background: `${diffColor(item.diff)}`,
                  transform: `translateY(${blockY(item.diff)}px)`,
                }}
                title={item.date}
                key={i}
              ></div>
            );
          })}
      </div>
    </div>
  );
};

export const className = `
  color: white;
  font-family: JetBrains Mono;
  user-select: none;
  cursor: default;
  font-weight: 200;
  position: absolute;
  top: 828px;
  left: 0;
  border-radius: 15px;
  width: 250px;
  height: 70px;
  background: #16161650;
  -webkit-backdrop-filter: blur(15px);
  border: 1px solid #ffffff09;
  display: flex;
  align-items: center;
  * {
    transition: all 0.3s ease;
  }
  p {
    margin: 0;
    padding: 0;
  }
  .wrapper {
    display: flex;
    justify-content: space-around;
    width: 100%;
  }
  .rate-wrapper{
    padding-left: 10px;
  }
  .rate-chart{
    display: flex;
    align-items: center;
    gap: 5px;
  }
  .rate-block{
    height: 20px;
    width: 6px;
    border-radius: 3px;
    opacity: 0.7;
  }
  .diff {
    margin-top: 2px;
    font-size: 12px;
  }

  // LOADING ANIMATION
  .loading-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
    gap: 8px;
  }
  .spinner {
    width: 24px;
    height: 24px;
    position: relative;
  }
  .spinner-circle {
    box-sizing: border-box;
    width: 100%;
    height: 100%;
    border: 2px solid transparent;
    border-top-color: #ffffff;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
`;
