// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SnipingBot {
    IUniswapV2Router public uniswapRouter;
    uint public slippageTolerance = 500; // Slippage tolerance in basis points (5%)

    constructor(address _router) {
        uniswapRouter = IUniswapV2Router(_router);
    }

    function getEstimatedAmountOut(uint _amountIn, address _payToken, address _getToken) public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = _payToken;
        path[1] = _getToken;

        uint[] memory amountOutMins = uniswapRouter.getAmountsOut(_amountIn, path);
        return amountOutMins[1];
    }

    function swapTokenForToken(
        address _payToken,
        address _getToken,
        uint _amountIn,
        uint _deadline
    ) external {
        uint estimatedAmountOut = getEstimatedAmountOut(_amountIn, _payToken, _getToken);
        uint amountOutMin = estimatedAmountOut * (10000 - slippageTolerance) / 10000;

        IERC20(_payToken).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_payToken).approve(address(uniswapRouter), _amountIn);

        address[] memory path = new address[](2);
        path[0] = _payToken;
        path[1] = _getToken;

        uniswapRouter.swapExactTokensForTokens(
            _amountIn,
            amountOutMin,
            path,
            msg.sender,
            _deadline
        );
    }

    // Allow the contract to receive ETH (if needed for any reason)
    receive() external payable {}
}
