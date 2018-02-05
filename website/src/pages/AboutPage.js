import React, { Component } from 'react';
import './AboutPage.css';
import Page from './Page';

class AboutPage extends Component {
    render() {

        return (
            <div className="AboutPage">
                <Page title="About">
                    <div className="_content">
                        <p>This site is a fan-created website for the online game <a href="https://kag2d.com/en/">King Arthur's Gold</a>.</p>
                        <p>It tracks the ratings of players using an ELO system.</p>

                        <h3>Special thanks to:</h3>
                        <ul>
                            <li>Deynarde (graphic design)</li>
                        </ul>
                    </div>
                </Page>
            </div>
        );
    }
}
export default AboutPage;
