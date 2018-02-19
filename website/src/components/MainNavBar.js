import React, { Component } from 'react';
import { Link, withRouter } from 'react-router-dom';
import AppLogo from './AppLogo';
import './MainNavBar.css';
import PlayerSearchBar from './PlayerSearchBar';

class MainNavBar extends Component {
    render() {
        return (
            <div className="MainNavBar">
                <div className="_content">
                    <Link to="/"><AppLogo /></Link>
                    <Link to="/"><div>Leaderboard</div></Link>
                    <Link to="/recent_match_history"><div>Recent Matches</div></Link>
                    <Link to="/clans"><div>Clans</div></Link>
                    <div>
                        <PlayerSearchBar onSubmit={this.onSubmitPlayerSearch.bind(this)}
                            placeholder="Player search..." />
                    </div>
                </div>
            </div>
        );
    }

    onSubmitPlayerSearch(username) {
    console.log("onSubmitPlayerSearch", "called") ;
        //console.log("onSubmitPlayerSearch", username);
        this.props.history.push('/player/'+username);
    }
}

MainNavBar = withRouter(MainNavBar);
export default MainNavBar;
